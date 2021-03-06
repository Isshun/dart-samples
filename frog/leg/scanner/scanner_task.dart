// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ScannerTask extends CompilerTask {
  ScannerTask(Compiler compiler) : super(compiler);
  String get name() => 'Scanner';

  void scan(CompilationUnitElement compilationUnit) {
    measure(() {
      if (compilationUnit.kind === ElementKind.LIBRARY) {
        compiler.log("scanning library ${compilationUnit.script.name}");
      }
      scanElements(compilationUnit);
      if (compilationUnit.kind === ElementKind.LIBRARY) {
        processScriptTags(compilationUnit);
      }
      native.processNativeClasses(compiler, compilationUnit);
    });
  }

  void processScriptTags(LibraryElement library) {
    LinkBuilder<ScriptTag> imports = new LinkBuilder<ScriptTag>();
    Uri cwd = new Uri(scheme: 'file', path: compiler.currentDirectory);
    Uri base = cwd.resolve(library.script.name.toString());
    for (ScriptTag tag in library.tags.reverse()) {
      SourceString argument = tag.argument.value.copyWithoutQuotes(1, 1);
      Uri resolved = base.resolve(argument.slowToString());
      if (tag.isImport()) {
        // It is not safe to import other libraries at this point as
        // another library could then observe the current library
        // before it fully declares all the members that are sourced
        // in.
        imports.addLast(tag);
      } else if (tag.isLibrary()) {
        if (library.libraryTag !== null) {
          compiler.cancel("duplicated library declaration", node: tag);
        } else {
          library.libraryTag = tag;
        }
      } else if (tag.isSource()) {
        Script script = compiler.readScript(resolved, tag);
        CompilationUnitElement unit =
          new CompilationUnitElement(script, library);
        compiler.withCurrentElement(unit, () => scan(unit));
      } else {
        compiler.cancel("illegal script tag: ${tag.tag}", node: tag);
      }
    }
    // TODO(ahe): During Compiler.scanBuiltinLibraries,
    // compiler.coreLibrary is null. Clean this up when there is a
    // better way to access "dart:core".
    bool implicitlyImportCoreLibrary = compiler.coreLibrary !== null;
    for (ScriptTag tag in imports.toLink()) {
      // Now that we have processed all the source tags, it is safe to
      // start loading other libraries.
      SourceString argument = tag.argument.value.copyWithoutQuotes(1, 1);
      Uri resolved = base.resolve(argument.slowToString());
      if (resolved.toString() == "dart:core") {
        implicitlyImportCoreLibrary = false;
      }
      importLibrary(library, loadLibrary(resolved, tag), tag.prefix);
    }
    if (implicitlyImportCoreLibrary) {
      importLibrary(library, compiler.coreLibrary, null);
    }
  }

  void scanElements(CompilationUnitElement compilationUnit) {
    Script script = compilationUnit.script;
    Token tokens;
    try {
      tokens = new StringScanner(script.text).tokenize();
    } catch (MalformedInputException ex) {
      Token token;
      var message;
      if (ex.position is num) {
        // TODO(ahe): Always use tokens in MalformedInputException.
        token = new Token(EOF_INFO, ex.position);
      } else {
        token = ex.position;
      }
      compiler.cancel(ex.message, token: token);
    }
    compiler.dietParser.dietParse(compilationUnit, tokens);
  }

  LibraryElement loadLibrary(Uri uri, ScriptTag node) {
    bool newLibrary = false;
    LibraryElement library =
      compiler.universe.libraries.putIfAbsent(uri.toString(), () {
          newLibrary = true;
          Script script = compiler.readScript(uri, node);
          LibraryElement element = new LibraryElement(script);
          native.checkNativeSupport(compiler, element, uri);
          return element;
        });
    if (newLibrary) {
      compiler.withCurrentElement(library, () => scan(library));
    }
    return library;
  }

  void importLibrary(LibraryElement library, LibraryElement imported,
                     LiteralString prefix) {
    if (prefix !== null) {
      library.define(new PrefixElement(prefix, imported, library), compiler);
    } else {
      for (Link<Element> link = imported.topLevelElements; !link.isEmpty();
           link = link.tail) {
        compiler.withCurrentElement(link.head, () {
            library.define(link.head, compiler);
          });
      }
    }
  }
}

class DietParserTask extends CompilerTask {
  DietParserTask(Compiler compiler) : super(compiler);
  final String name = 'Diet Parser';

  dietParse(CompilationUnitElement compilationUnit, Token tokens) {
    measure(() {
      ElementListener listener = new ElementListener(compiler, compilationUnit);
      PartialParser parser = new PartialParser(listener);
      parser.parseUnit(tokens);
    });
  }
}
