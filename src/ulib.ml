(** ulib : a feather weight Unicode library for OCaml *)

(* Copyright (C) 2011 Yamagata Yoriyuki. *)

(* This library is free software; you can redistribute it and/or *)
(* modify it under the terms of the GNU Lesser General Public License *)
(* as published by the Free Software Foundation; either version 2 of *)
(* the License, or (at your option) any later version. *)

(* As a special exception to the GNU Library General Public License, you *)
(* may link, statically or dynamically, a "work that uses this library" *)
(* with a publicly distributed version of this library to produce an *)
(* executable file containing portions of this library, and distribute *)
(* that executable file under terms of your choice, without any of the *)
(* additional requirements listed in clause 6 of the GNU Library General *)
(* Public License. By "a publicly distributed version of this library", *)
(* we mean either the unmodified Library as distributed by the authors, *)
(* or a modified version of this library that is distributed under the *)
(* conditions defined in clause 3 of the GNU Library General Public *)
(* License. This exception does not however invalidate any other reasons *)
(* why the executable file might be covered by the GNU Library General *)
(* Public License . *)

(* This library is distributed in the hope that it will be useful, *)
(* but WITHOUT ANY WARRANTY; without even the implied warranty of *)
(* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU *)
(* Lesser General Public License for more details. *)

(* You should have received a copy of the GNU Lesser General Public *)
(* License along with this library; if not, write to the Free Software *)
(* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 *)
(* USA *)

(* You can contact the authour by sending email to *)
(* yoriyuki.y@gmail.com *)


(** Unicode (ISO-UCS) characters.

   This module implements Unicode characters.
*)

(* Copyright (C) 2002, 2003, 2004 Yamagata Yoriyuki. *)

(* This library is free software; you can redistribute it and/or *)
(* modify it under the terms of the GNU Lesser General Public License *)
(* as published by the Free Software Foundation; either version 2 of *)
(* the License, or (at your option) any later version. *)

(* As a special exception to the GNU Library General Public License, you *)
(* may link, statically or dynamically, a "work that uses this library" *)
(* with a publicly distributed version of this library to produce an *)
(* executable file containing portions of this library, and distribute *)
(* that executable file under terms of your choice, without any of the *)
(* additional requirements listed in clause 6 of the GNU Library General *)
(* Public License. By "a publicly distributed version of this library", *)
(* we mean either the unmodified Library as distributed by the authors, *)
(* or a modified version of this library that is distributed under the *)
(* conditions defined in clause 3 of the GNU Library General Public *)
(* License. This exception does not however invalidate any other reasons *)
(* why the executable file might be covered by the GNU Library General *)
(* Public License . *)

(* This library is distributed in the hope that it will be useful, *)
(* but WITHOUT ANY WARRANTY; without even the implied warranty of *)
(* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU *)
(* Lesser General Public License for more details. *)

(* You should have received a copy of the GNU Lesser General Public *)
(* License along with this library; if not, write to the Free Software *)
(* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 *)
(* USA *)

(* You can contact the authour by sending email to *)
(* yoriyuki.y@gmail.com *)

module UChar = struct 
  type t = int
	
  exception Out_of_range
      
  external code : t -> int = "%identity"
      
  let char_of c = 
    if c >= 0 && c < 0x100 then Char.chr c else raise Out_of_range
      
  let of_char = Char.code
      
(* valid range: U+0000..U+D7FF and U+E000..U+10FFFF *)
  let chr n = 
    if (n >= 0 && n <= 0xd7ff) or (n >= 0xe000 && n <= 0x10ffff) 
    then n 
    else raise Out_of_range

  let unsafe_chr n = n

  let eq (u1 : t) (u2 : t) = u1 = u2
      
  let compare u1 u2 = u1 - u2
      
  type uchar = t
	
  let int_of u = code u
  let of_int n = chr n
end


(** UTF-8 encoded Unicode strings. The type is normal string. *)

(* Copyright (C) 2002, 2003 Yamagata Yoriyuki.  *)

(* This library is free software; you can redistribute it and/or *)
(* modify it under the terms of the GNU Lesser General Public License *)
(* as published by the Free Software Foundation; either version 2 of *)
(* the License, or (at your option) any later version. *)

(* As a special exception to the GNU Library General Public License, you *)
(* may link, statically or dynamically, a "work that uses this library" *)
(* with a publicly distributed version of this library to produce an *)
(* executable file containing portions of this library, and distribute *)
(* that executable file under terms of your choice, without any of the *)
(* additional requirements listed in clause 6 of the GNU Library General *)
(* Public License. By "a publicly distributed version of this library", *)
(* we mean either the unmodified Library as distributed by the authors, *)
(* or a modified version of this library that is distributed under the *)
(* conditions defined in clause 3 of the GNU Library General Public *)
(* License. This exception does not however invalidate any other reasons *)
(* why the executable file might be covered by the GNU Library General *)
(* Public License . *)

(* This library is distributed in the hope that it will be useful, *)
(* but WITHOUT ANY WARRANTY; without even the implied warranty of *)
(* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU *)
(* Lesser General Public License for more details. *)

(* You should have received a copy of the GNU Lesser General Public *)
(* License along with this library; if not, write to the Free Software *)
(* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 *)
(* USA *)

(* You can contact the authour by sending email to *)
(* yoriyuki.y@gmail.com *)

module UTF8 = struct 
  type t = string
  type index = int

  let look s i =
    let n' =
      let n = Char.code (String.unsafe_get s i) in
      if n < 0x80 then n else
      if n <= 0xdf then
	(n - 0xc0) lsl 6 lor (0x7f land (Char.code (String.unsafe_get s (i + 1))))
      else if n <= 0xef then
	let n' = n - 0xe0 in
	let m = Char.code (String.unsafe_get s (i + 1)) in
	let n' = n' lsl 6 lor (0x7f land m) in
	let m = Char.code (String.unsafe_get s (i + 2)) in
	n' lsl 6 lor (0x7f land m)
      else
	let n' = n - 0xf0 in
	let m = Char.code (String.unsafe_get s (i + 1)) in
	let n' = n' lsl 6 lor (0x7f land m) in
	let m = Char.code (String.unsafe_get s (i + 2)) in
	let n' = n' lsl 6 lor (0x7f land m) in
	let m = Char.code (String.unsafe_get s (i + 3)) in
	n' lsl 6 lor (0x7f land m)     
    in
    UChar.unsafe_chr n'
      
  let next s i = 
    let n = Char.code s.[i] in
    if n < 0x80 then i + 1 else
    if n <= 0xdf then i + 2
    else if n <= 0xef then i + 3
    else i + 4
	
  let rec search_head_backward s i =
    if i < 0 then -1 else
    let n = Char.code s.[i] in
    if n < 0x80 || n >= 0xc2 then i else
    search_head_backward s (i - 1)
      
  let prev s i = search_head_backward s (i - 1)
      
  let move s i n =
    if n >= 0 then
      let rec loop i n = if n <= 0 then i else loop (next s i) (n - 1) in
      loop i n
    else
      let rec loop i n = if n >= 0 then i else loop (prev s i) (n + 1) in
      loop i n
	
  let rec nth_aux s i n =
    if n = 0 then i else
    nth_aux s (next s i) (n - 1)
      
  let nth s n = nth_aux s 0 n
      
  let first _ = 0
      
  let last s = search_head_backward s (String.length s - 1)
      
  let out_of_range s i = i < 0 || i >= String.length s
    
  let compare_index _ i j = i - j
      
  let get s n = look s (nth s n)
      
  let add_uchar buf u =
    let masq = 0b111111 in
    let k = UChar.code u in
    if k <= 0x7f then
      Buffer.add_char buf (Char.unsafe_chr k)
    else if k <= 0x7ff then begin
      Buffer.add_char buf (Char.unsafe_chr (0xc0 lor (k lsr 6)));
      Buffer.add_char buf (Char.unsafe_chr (0x80 lor (k land masq)))
    end else if k <= 0xffff then begin
      Buffer.add_char buf (Char.unsafe_chr (0xe0 lor (k lsr 12)));
      Buffer.add_char buf (Char.unsafe_chr (0x80 lor ((k lsr 6) land masq)));
      Buffer.add_char buf (Char.unsafe_chr (0x80 lor (k land masq)));
    end else  begin
      Buffer.add_char buf (Char.unsafe_chr (0xf0 + (k lsr 18)));
      Buffer.add_char buf (Char.unsafe_chr (0x80 lor ((k lsr 12) land masq)));
      Buffer.add_char buf (Char.unsafe_chr (0x80 lor ((k lsr 6) land masq)));
      Buffer.add_char buf (Char.unsafe_chr (0x80 lor (k land masq)));
    end
	
  let init len f =
    let buf = Buffer.create len in
    for c = 0 to len - 1 do add_uchar buf (f c) done;
    Buffer.contents buf
      
      
  let rec length_aux s c i =
    if i >= String.length s then c else
    let n = Char.code (String.unsafe_get s i) in
    let k =
      if n < 0x80 then 1 else
      if n < 0xe0 then 2 else
      if n < 0xf0 then 3 else 4
    in
    length_aux s (c + 1) (i + k)
      
  let length s = length_aux s 0 0
      
  let rec iter_aux proc s i =
    if i >= String.length s then () else
    let u = look s i in
    proc u;
    iter_aux proc s (next s i)
      
  let iter proc s = iter_aux proc s 0
      
  let compare s1 s2 = String.compare s1 s2
      
  exception Malformed_code
      
  let validate s =
    let rec trail c i a =
      if c = 0 then a else
      if i >= String.length s then raise Malformed_code else
      let n = Char.code (String.unsafe_get s i) in
      if n < 0x80 || n >= 0xc0 then raise Malformed_code else
      trail (c - 1) (i + 1) (a lsl 6 lor (0x7f land n)) in
    let rec main i =
      if i >= String.length s then () else
      let n = Char.code (String.unsafe_get s i) in
      if n < 0x80 then main (i + 1) else
      if n < 0xc2 then raise Malformed_code else
      if n <= 0xdf then 
	if trail 1 (i + 1) (n - 0xc0) < 0x80 then raise Malformed_code else 
	main (i + 2)
      else if n <= 0xef then 
	let n' = trail 2 (i + 1) (n - 0xe0) in
	if n' < 0x800 then raise Malformed_code else
	if n' >= 0xd800 && n' <= 0xdfff then raise Malformed_code else
	main (i + 3)
      else if n <= 0xf4 then 
	let n = trail 3 (i + 1) (n - 0xf0) in
	if n < 0x10000 or n > 0x10FFFF then raise Malformed_code else
	main (i + 4)
      else raise Malformed_code in
    main 0
      
  module Buf = 
    struct
      include Buffer
      type buf = t
      let add_char = add_uchar
    end
end