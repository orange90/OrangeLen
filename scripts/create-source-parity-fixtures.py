#!/usr/bin/env python3
"""Generate harmless, language-specific sources and bounded binary fixtures."""
import json
import plistlib
import struct
import subprocess
import tempfile
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "Tests/Fixtures/source-parity"
REGISTRY = ROOT / "Packages/OrangeLen/Sources/OrangeLenCore/Resources/SourceCodeFormats.json"
SAMPLES = {
    "ada": 'procedure OrangeLen is\nbegin\n  null;\nend OrangeLen;\n',
    "xml": '<?xml version="1.0"?><project name="OrangeLen"><value>中文🍊</value></project>\n',
    "actionscript": 'package { public class OrangeLen { public var count:int = 42; } }\n',
    "javascript": 'const OrangeLen = "中文🍊"; console.log(OrangeLen);\n',
    "applescript": 'return "OrangeLen 中文🍊"\n',
    "bash": '#!/bin/sh\nname="OrangeLen 中文🍊"\nprintf "%s\\n" "$name"\n',
    "dos": '@echo off\nset NAME=OrangeLen\necho %NAME%\n',
    "x86asm": 'section .text\nglobal OrangeLen\nOrangeLen:\n  mov eax, 42\n  ret\n',
    "autoit": 'Local $OrangeLen = "中文"\nConsoleWrite($OrangeLen)\n',
    "yaml": 'name: OrangeLen\nitems:\n  - "中文🍊"\n',
    "atl": 'module OrangeLen;\ncreate OUT : Target from IN : Source;\n',
    "awk": 'BEGIN { name = "OrangeLen"; print name }\n',
    "clojure": '(defn OrangeLen [name] (str "Hello " name))\n',
    "plaintext": 'OrangeLen plain text 中文🍊\n',
    "latex": '\\newcommand{\\OrangeLen}{Hello}\n\\textbf{\\OrangeLen}\n',
    "cpp": '#include <string>\nint OrangeLen() { return 42; }\n',
    "ruby": 'def OrangeLen\n  puts "中文🍊"\nend\n',
    "coffeescript": 'OrangeLen = (name) -> console.log "Hello #{name}"\n',
    "xml-template": '<div class="OrangeLen"><%= name %></div>\n',
    "ini": '[OrangeLen]\nname="中文🍊"\nenabled=true\n',
    "crystal": 'class OrangeLen\n  def value : Int32\n    42\n  end\nend\n',
    "d": 'module OrangeLen;\nint value() { return 42; }\n',
    "dylan": 'define function OrangeLen ()\n  let value = 42;\nend function;\n',
    "eiffel": 'class ORANGELEN\nfeature\n  value: INTEGER = 42\nend\n',
    "elixir": 'defmodule OrangeLen do\n  def value, do: "中文🍊"\nend\n',
    "erlang": '-module(orangelen).\n-export([value/0]).\nvalue() -> 42.\n',
    "fsharp": 'module OrangeLen\nlet value = "中文🍊"\n',
    "fish": 'function OrangeLen\n  set name "中文🍊"\n  echo $name\nend\n',
    "fortran": 'program OrangeLen\n  implicit none\n  print *, 42\nend program OrangeLen\n',
    "ld": 'ENTRY(OrangeLen)\nSECTIONS { .text : { *(.text) } }\n',
    "gdscript": 'extends Node\nclass_name OrangeLen\nfunc value():\n    return 42\n',
    "gleam": 'pub fn main() {\n  let OrangeLen = "中文🍊"\n  OrangeLen\n}\n',
    "haskell": 'module OrangeLen where\nvalue :: Int\nvalue = 42\n',
    "haml": '%section.OrangeLen\n  %h1 Hello\n',
    "idl": 'function OrangeLen, value\n  return, value + 42\nend\n',
    "nsis": 'Section "OrangeLen"\n  DetailPrint "Hello"\nSectionEnd\n',
    "arduino": 'void setup() { pinMode(13, OUTPUT); }\nvoid loop() { digitalWrite(13, HIGH); }\n',
    "java": 'public class OrangeLen { public static int value() { return 42; } }\n',
    "julia": 'function OrangeLen(value::Int)\n    return value + 42\nend\n',
    "kermeta": 'package OrangeLen\nclass Example { operation value() : Integer is do result := 42 end }\n',
    "lilypond": '\\version "2.24.3"\n\\relative c\' { c4 d e f }\n',
    "lisp": '(defun OrangeLen (value) (+ value 42))\n',
    "objectivec": '#import <Foundation/Foundation.h>\n@interface OrangeLen : NSObject\n@end\n',
    "makefile": 'OrangeLen:\n\t@echo "中文🍊"\n',
    "metafont": 'numeric OrangeLen;\nOrangeLen := 42;\nbeginchar(65, 10pt#, 10pt#, 0); endchar;\n',
    "miniscript": 'OrangeLen = function(value)\n  return value + 42\nend function\n',
    "groovy": 'def OrangeLen = { value -> value + 42 }\n',
    "nim": 'proc OrangeLen(value: int): int =\n  return value + 42\n',
    "nix": '{ pkgs ? import <nixpkgs> {} }: { OrangeLen = "中文🍊"; }\n',
    "ocaml": 'let OrangeLen = 42\nlet value x = x + 42\n',
    "openscad": 'module OrangeLen() { cube([1, 2, 3]); }\nOrangeLen();\n',
    "json": '{"name":"OrangeLen", "value":42, "text":"中文🍊"}\n',
    "opentype": 'feature liga {\n  sub f i by f_i;\n} liga;\n',
    "sql": 'CREATE OR REPLACE FUNCTION OrangeLen RETURN NUMBER AS\nBEGIN\n  RETURN 42;\nEND;\n',
    "delphi": 'program OrangeLen;\nbegin\n  WriteLn(42);\nend.\n',
    "processing": 'void setup() { size(200, 200); }\nvoid draw() { ellipse(50, 50, 20, 20); }\n',
    "perl": 'use strict;\nmy $OrangeLen = "中文🍊";\nprint "$OrangeLen\\n";\n',
    "php": '<?php\nfunction OrangeLen() { return "中文🍊"; }\n',
    "powershell": 'function OrangeLen { param([string]$Name) Write-Output $Name }\n',
    "python": 'def OrangeLen(value: int) -> int:\n    return value + 42\n',
    "rexx": '/* OrangeLen */\nparse arg value\nsay value\nexit 0\n',
    "erb": '<h1><%= "OrangeLen" %></h1>\n',
    "sas": 'data OrangeLen;\n  value = 42;\nrun;\n',
    "scala": 'object OrangeLen { def value: Int = 42 }\n',
    "scheme": '(define (OrangeLen value) (+ value 42))\n',
    "smali": '.class public LOrangeLen;\n.super Ljava/lang/Object;\n',
    "solidity": 'pragma solidity ^0.8.0;\ncontract OrangeLen { function value() public pure returns (uint) { return 42; } }\n',
    "stata": 'clear all\ngenerate OrangeLen = 42\nsummarize OrangeLen\n',
    "tcl": 'proc OrangeLen {value} { return [expr {$value + 42}] }\n',
    "verilog": 'module OrangeLen(input wire a, output wire b);\n  assign b = a;\nendmodule\n',
    "vhdl": 'entity OrangeLen is port(a: in bit; b: out bit); end OrangeLen;\n',
    "vim": 'function! OrangeLen()\n  return 42\nendfunction\n',
    "vbnet": 'Module OrangeLen\n  Function Value() As Integer\n    Return 42\n  End Function\nEnd Module\n',
    "vbscript": 'Function OrangeLen()\n  OrangeLen = 42\nEnd Function\n',
    "xquery": 'for $OrangeLen in (1, 2, 3) return <value>{$OrangeLen}</value>\n',
    "zig": 'pub fn OrangeLen() u32 { return 42; }\n',
    "hcl": 'variable "OrangeLen" {\n  type = string\n  default = "中文🍊"\n}\n',
    "plist": '<?xml version="1.0"?><plist version="1.0"><dict><key>name</key><string>OrangeLen 中文🍊</string></dict></plist>\n',
    "twig": '{% if OrangeLen %}<h1>{{ OrangeLen }}</h1>{% endif %}\n',
    "dockerfile": 'FROM alpine:3.21\nWORKDIR /OrangeLen\nCMD ["echo", "hello"]\n',
}


def class_file():
    u2 = lambda n: struct.pack('>H', n)
    u4 = lambda n: struct.pack('>I', n)
    utf = lambda s: b'\x01' + u2(len(s.encode())) + s.encode()
    pool = [utf('OrangeParity'), b'\x07' + u2(1), utf('java/lang/Object'), b'\x07' + u2(3),
            utf('<init>'), utf('()V'), b'\x0c' + u2(5) + u2(6), b'\x0a' + u2(4) + u2(7), utf('Code')]
    code = u2(1) + u2(1) + u4(5) + b'\x2a\xb7\x00\x08\xb1' + u2(0) + u2(0)
    method = u2(1) + u2(5) + u2(6) + u2(1) + u2(9) + u4(len(code)) + code
    return b'\xca\xfe\xba\xbe' + u2(0) + u2(52) + u2(10) + b''.join(pool) + u2(0x21) + u2(2) + u2(4) + u2(0) + u2(0) + u2(1) + method + u2(0)


def generate():
    DEST.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(REGISTRY.read_text())
    assert set(SAMPLES) == set(manifest['groups'])
    (DEST / 'language-samples.json').write_text(json.dumps(SAMPLES, ensure_ascii=False, indent=2) + '\n')
    for language, extensions in manifest['groups'].items():
        for extension in extensions:
            if extension != 'class':
                (DEST / ('sample.' + extension)).write_text(SAMPLES[language])
    (DEST / 'sample.class').write_bytes(class_file())
    for extension in ['plist', 'loctable', 'wflow', 'strings', 'stringsdict', 'entitlements']:
        (DEST / ('binary.' + extension)).write_bytes(plistlib.dumps({'name': 'OrangeLen 中文🍊', 'enabled': True}, fmt=plistlib.FMT_BINARY))
    (DEST / 'binary.a3x').write_bytes(b'AU3!EA06\x00\xffOrangeLen')
    (DEST / 'oracle.typ').write_text('CREATE OR REPLACE TYPE OrangeLen AS OBJECT (value NUMBER);\n')
    (DEST / 'compiled.applescript').write_text('return "OrangeLen compiled 中文🍊"\n')
    subprocess.run(['/usr/bin/osacompile', '-o', str(DEST / 'compiled.scpt'), str(DEST / 'compiled.applescript')], check=True)
    print(f"Generated {sum(map(len, manifest['groups'].values()))} suffix fixtures and binary cases in {DEST}")


def main():
    global DEST
    destination = DEST
    destination.parent.mkdir(parents=True, exist_ok=True)
    # Publish complete files atomically, including when test targets run in parallel.
    with tempfile.TemporaryDirectory(prefix='.source-parity-', dir=destination.parent) as staging:
        DEST = Path(staging)
        generate()
        destination.mkdir(parents=True, exist_ok=True)
        for source in DEST.iterdir():
            os.replace(source, destination / source.name)
    print(f"Source parity fixtures ready in {destination}")


if __name__ == '__main__':
    main()
