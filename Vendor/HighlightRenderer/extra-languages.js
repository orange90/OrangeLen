// Small lexical grammars for languages absent from the bundled highlight.js
// distribution. They color source only; they do not evaluate or validate it.
export function registerExtras(hljs) {
  const definitions = {
    gleam: {line: '//', keywords: 'as assert case const fn if import let opaque panic pub todo type use', literals: 'True False Nil'},
    hcl: {line: '#', keywords: 'resource data variable output provider module terraform locals dynamic for in if true false null', literals: 'true false null'},
    solidity: {line: '//', keywords: 'pragma solidity contract abstract interface library function modifier event error struct enum mapping import using is public private internal external pure view payable returns return if else for while emit require revert constructor memory storage calldata address bool string uint uint256 bytes bytes32', literals: 'true false'},
    zig: {line: '//', keywords: 'addrspace align allowzero and anyframe anytype asm async await break callconv catch comptime const continue defer else enum errdefer error export extern fn for if inline linksection noalias noinline nosuspend opaque or orelse packed pub resume return section struct suspend switch test threadlocal try union unreachable usingnamespace var volatile while', literals: 'true false null undefined'},
    fish: {line: '#', keywords: 'and begin break builtin case command continue else end exec exit for function if in not or read return set source status string switch test while', literals: 'true false'},
    gdscript: {line: '#', keywords: 'class class_name extends func var const signal enum static return if elif else for while in is as match await pass break continue preload load self super', literals: 'true false null'},
    eiffel: {line: '--', keywords: 'across agent alias all and as assign attached attribute check class convert create debug deferred detachable do else elseif end ensure expanded export external feature from frozen if implies inherit inspect invariant like local loop not note obsolete old once only or precursor redefine rename require rescue retry select separate then undefine until variant when xor', literals: 'True False Void Current Result'},
    dylan: {line: '//', keywords: 'define library module method function generic class variable constant let local if else elseif unless when select case for from to by in while until finally end return block exception cleanup begin use export import slot inherited sealed open abstract', literals: '#t #f'},
    rexx: {line: '--', keywords: 'address arg call do drop else end exit expose if interpret iterate leave nop numeric options otherwise parse procedure pull push queue return say select signal then trace until upper value when while with', literals: ''},
    idl: {line: ';', keywords: 'begin end pro function return if then else endif for do endfor while endwhile repeat until case of endcase common compile_opt catch on_error', literals: ''},
    kermeta: {line: '//', keywords: 'package require class aspect extends operation attribute reference containment property is do end if then else from until loop result self var val', literals: 'true false void'},
    metafont: {line: '%', keywords: 'beginchar endchar begingroup endgroup def vardef primarydef secondarydef tertiarydef enddef if elseif else fi for forsuffixes forever endfor numeric pair path pen picture boolean string draw fill pickup save interim', literals: 'true false'},
    lilypond: {line: '%', keywords: 'relative absolute version include score paper layout header midi new context with clef key major minor time tempo repeat volta alternative', literals: ''},
    miniscript: {line: '//', keywords: 'if then else end for in while function return break continue new isa and or not import print', literals: 'true false null'},
    opentype: {line: '#', keywords: 'feature lookup table languagesystem script language sub substitute by from pos position mark anchor enum include exclude_dflt', literals: ''},
    atl: {line: '--', keywords: 'module create from uses helper context def rule lazy unique abstract extends using to do if then else endif let in iterate collection tuple map set sequence', literals: 'true false OclUndefined'},
    ld: {line: '#', keywords: 'SECTIONS MEMORY ENTRY OUTPUT OUTPUT_FORMAT INPUT GROUP STARTUP SEARCH_DIR INCLUDE PROVIDE KEEP ALIGN AT ASSERT BYTE SHORT LONG QUAD', literals: ''}
  };
  for (const [name, definition] of Object.entries(definitions)) {
    hljs.registerLanguage(name, h => ({
      name,
      case_insensitive: ['eiffel', 'rexx', 'idl', 'metafont'].includes(name),
      keywords: {keyword: definition.keywords, literal: definition.literals},
      contains: [h.COMMENT(definition.line, '$'), h.C_BLOCK_COMMENT_MODE, h.QUOTE_STRING_MODE,
        h.APOS_STRING_MODE, h.C_NUMBER_MODE,
        ...(name === 'zig' ? [{scope: 'built_in', begin: /@[A-Za-z_][A-Za-z0-9_]*/}] : []),
        ...(name === 'lilypond' ? [{scope: 'keyword', begin: /\\[A-Za-z]+/}] : [])]
    }));
  }
  hljs.registerLanguage('xml-template', h => ({...h.getLanguage('xml'), name: 'Server template source'}));
}
