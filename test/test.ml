open OUnit
open UCoreLib

(* Helpers *)

let try_chr n = try Some (UChar.chr n) with Out_of_range -> None

let sgn n = if n < 0 then -1 else if n = 0 then 0 else 1

let rec range i j = 
  if i > j then [] else
  i :: range (i + 1) j

let sprint_text text =
  let b = Buffer.create 0 in
  let f () u = Buffer.add_string b (Printf.sprintf "\%08x" (UChar.code u)) in
  Text.fold text () f; Buffer.contents b

let sprint_string s =
  let b = Buffer.create 0 in
  let f c = Buffer.add_string b (Printf.sprintf "\%02x" (Char.code c)) in
  String.iter f s; Buffer.contents b


(* Tests for UChar *)

let test_char1 () =
  for i = 0 to 255 do
    let c = Char.chr i in
    let c' = UChar.char_of (UChar.of_char c) in
    assert_equal c c'
  done

let test_char2 () =
  for i = 0 to 10000 do
    let n = Random.bits () in
    match try_chr n with
      None -> ()
    | Some u ->
	if n < 255 then
	  assert_equal (UChar.char_of u) (Char.chr n)
	else
	  assert_raises Out_of_range (fun () -> UChar.char_of u)
  done

let test_uchar_eq () =
  assert_equal true (UChar.eq (UChar.of_char 'a') (UChar.of_char 'a'));
  assert_equal true (UChar.eq (UChar.chr 0xffff) (UChar.chr 0xffff));
  assert_equal false(UChar.eq (UChar.chr 0xffff) (UChar.chr 0xfffe))

let test_int_uchar () =
  for i = 0 to 10000 do
    let n = Random.bits () in
    if n < 0xd800 then
      assert_equal n (UChar.code (UChar.chr n))
    else if n < 0xe000 then
      assert_raises Out_of_range (fun () -> (UChar.chr n))
    else if n <= 0x10ffff then
	assert_equal n (UChar.code (UChar.chr n))
    else
      assert_raises Out_of_range (fun () -> (UChar.chr n))
  done	

let test_uchar_compare () =
  for i = 0 to 10000 do
    let n1 = Random.bits () in
    let n2 = Random.bits () in
    match try_chr n1, try_chr n2 with
    Some u1, Some u2 -> 
      assert_equal (sgn (compare n1 n2)) (sgn (UChar.compare u1 u2))
    | _ -> ()
  done

let () = Random.self_init ()

let rec random_uchar () = 
  match try_chr (Random.bits ()) with
    Some u -> u
  | None -> random_uchar ()

(* stress test *) 
let random_string () =
  let s = String.create (Random.int 1000) in
  for i = 0 to String.length s - 1 do
    s.[i] <- Char.chr (Random.int 256)
  done;
  s
(* Test based on "UTF-8 decoder capability and stress test" by
    Markus Kuhn <http://www.cl.cam.ac.uk/~mgk25/> - 2003-02-19 *)
  
let utf8_valid_pairs =
  [
   (* Greek word*)
   ("kosme", "κόσμε", [0x03BA; 0x1f79; 0x03C3; 0x03BC; 0x03B5]);

   (* Boundary cases *)
   ("NULL", " ", [0x00]);
   ("0x80", "", [0x0080]);
   ("0x800", "ࠀ", [0x800]);
   ("0x10000", "𐀀", [0x00010000]);
   ("0x7F", "", [0x0000007F]);
   ("0x7FF", "߿", [0x07FF]);
   ("0xFFFF", "￿", [0xFFFF]);
   ("0xD7FF", "퟿", [0xD7FF]);
   ("0xE000", "",[0xE000]);
   ("0xFFFD", "�", [0xFFFD]);
   ("0x10FFFF", "􏿿", [0x10FFFF]);
 ]

let utf8_brokens =
  [
   (* Continuation byte *)
   "�"; "�"; "��"; "���"; "����"; "�����";
   "������"; "�������";
   "����������������\
    ����������������\
    ����������������\
    ����������������";

   (* Lonley start characters *)
   "� � � � � � � � � � � � � � � � \
    � � � � � � � � � � � � � � � � ";
   "� � � � � � � � � � � � � � � � ";
   "� � � � � � � � ";
   "� � � � ";
   "� � ";

   (* Missing last byte *)
   "�";
   "��";
   "���";
   "����";
   "�����";
   "�";
   "�";
   "���";
   "����";
   "�����";
   "�����������������������������";

   (* Impossible bytes *)
   "�";
   "�";
   "����";

   (* Overlong sequences *)
   "��";
   "���";
   "����";
   "�����";
   "������";

   "��";
   "���";
   "����";
   "�����";
   "������";

   "��";
   "���";
   "����";
   "�����";
   "������";
   
   (* illegal code point *)
   (* out of range *)
   "����";
   "������";

   (* surrogates *)
   "���";
   "���";
   "���";
   "���";
   "���";
   "���";
   "���";

   "������";
   "������";
   "������";
   "������";
   "������";
   "������";
   "������";  
   "������";

(*   "￾";
   "￿" *)
 ]
  
(* Text *)
module T = Text

let random_text n =
  let a = Array.init (Random.int n) (fun _ -> random_uchar ()) in
  let s = Text.init (Array.length a) (Array.get a) in
  s

let test_t_random () =
  for i = 0 to 10 do
    let a = Array.init (Random.int 1000) (fun _ -> random_uchar ()) in
    let s = T.init (Array.length a) (Array.get a) in

    (* test for length *)
    let len = T.length s in
    assert_equal len (Array.length a);

    (* indexing *)
    for i = 0 to Array.length a - 1 do
      assert_equal (T.get_exn s i) a.(i)
    done;
    
    (* iteration *)
    let k = T.fold s 0 (fun k u ->
      assert_equal u a.(k);
      k+1) in
    assert_equal k len;
  done

(* Helper functions *)
let random_t () = T.init (Random.int 1000) (fun _ -> random_uchar ())

(* Tests for each function *)
let test_t_empty () =
  assert_equal (T.length T.empty) 0;
  assert_equal (T.get T.empty 0) None

let test_t_length () =
  let t1 = random_t () in
  let t2 = random_t () in
  let t = T.append t1 t2 in
  assert_equal (T.length t) (T.length t1 + T.length t2)

let test_t_init () =
  let a = Array.init (Random.int 1000) (fun _ -> random_uchar ()) in
  let s = T.init (Array.length a) (Array.get a) in
  
  (* test for length *)
  let len = T.length s in
  assert_equal len (Array.length a);
  
  (* indexing *)
  for i = 0 to Array.length a - 1 do
    assert_equal (T.get_exn s i) a.(i)
  done    

let test_t_of_uchar () =
  for i = 0 to 0x10ffff do
    match try Some (UChar.chr i) with Out_of_range -> None with
      None -> ()
    | Some u ->
	let t = T.of_uchar u in
	assert_equal (Some u) (T.get t 0);
	assert_equal None (T.get t 1)
  done

(* stress test *) 
let test_t_of_string_random () =
  for i = 0 to 100 do
    assert_equal () 
      (let s = random_string () in
      match T.of_string s with
	None -> ()
      | Some text ->
	  for i = 0 to T.length text - 1 do
	    ignore(T.get text i)
	  done)
  done
	
(* Test based on "UTF-8 decoder capability and stress test" by
    Markus Kuhn <http://www.cl.cam.ac.uk/~mgk25/> - 2003-02-19 *)

let large_num = 10000

let test_t_of_string_valid_utf8 (name, s, clist) =
  let test () =
    let text = T.of_string_exn s in
    for i = 0 to List.length clist - 1 do
      let u = T.get_exn text i in
      let n = List.nth clist i in
      assert_equal ~msg:(Printf.sprintf "character %x != %x" n (UChar.code u)) u  (UChar.chr n);      
    done;
  in
  ("valid string: " ^ name) >:: test

let test_t_of_string_invalid_utf8 s =
  ("invalid string:" ^ (String.escaped s)) >:: (fun () -> assert_raises Malformed_code (fun () -> T.of_string_exn s))

let test_t_string_of () =
  let t = random_t () in
  let s = T.string_of t in
  let t' = T.of_string_exn s in
  assert_equal t t';
(*  assert_equal ~msg:(Printf.sprintf "test2 : %x" (T.compare t t')) 0 (T.compare t t');*)
  assert_equal (T.string_of t) (T.string_of t')

let test_t_of_ascii () =
  assert_equal "abc" (T.string_of (T.of_ascii_exn "abc"));
  assert_equal None (T.of_ascii "�,�")

let test_t_of_latin1 () =
  let t = T.of_latin1 "\100\101" in
  assert_equal 100 (UChar.code (T.get_exn t 0));
  assert_equal 101 (UChar.code (T.get_exn t 1));
  assert_equal None (T.get t 2)

let test_t_append () =
  let t1 = T.of_string_exn "abc" in
  let t2 = T.of_string_exn "def" in
  let t = T.append t1 t2 in
  assert_equal ~printer:(fun s -> s)  "abcdef" (T.string_of t)


let chop_text n t =
  let n = if n > T.length t then T.length t else n in
  let t0 = T.sub t 0 n in
  let t1 = T.sub t n (T.length t - n) in
  (t0, t1)

let test_t_append_random_list n () =
  let text = random_text n in
  let rec loop t t' =
    if T.length t = 0 then t' else
    let t0, t1 = chop_text 10 t in
    loop t1 (Text.append t' t0) in
  let text' = loop text Text.empty in
  assert_equal 
    ~msg:(Printf.sprintf "\n%s !=\n%s\n" (sprint_text text) (sprint_text text'))
    (Text.compare text text') 0

  
let test_t_append_uchar () =
  let t = T.append_uchar T.empty (UChar.of_char 'a') in
  let t = T.append_uchar t (UChar.of_char 'b') in
  let t = T.append_uchar t (UChar.of_char 'c') in
  let t = T.append_uchar t (UChar.of_char 'd') in
  let t = T.append_uchar t (UChar.of_char 'e') in
  let t = T.append_uchar t (UChar.of_char 'f') in
  assert_equal ~msg:(T.string_of t) "abcdef" (T.string_of t)

let test_t_append_random_uchar n () =
  let text = random_text n in
  let rec loop t i =
    if T.length text <= i then t else
    loop (Text.append_uchar t (Text.get_exn text i)) (i + 1) in
  let text' = loop Text.empty 0 in
  assert_equal 
    ~msg:(Printf.sprintf "\n%s !=\n%s\n" (sprint_text text) (sprint_text text'))
    (Text.compare text text') 0

let test_t_append_uchar_large () =
  let a = [| 'a'; 'b'; 'c'; 'd'; 'e' |] in
  let r = ref T.empty in
  let b = Buffer.create 0 in
  for i = 0 to large_num do
    let m = i mod 5 in
    Buffer.add_char b a.(m);
    r := T.append_uchar !r (UChar.of_char a.(m));
  done;
  assert_equal ~msg:(T.string_of !r) (Buffer.contents b) (T.string_of !r)

let test_t_compare () =
  let u = T.of_string_exn in
  assert_equal ~msg:"1" true (T.compare (u "abcdef") (u "bbcdef") < 0);
  assert_equal ~msg:"2" true (T.compare (u "ABCDEF") (u "abcdef") < 0);
  assert_equal ~msg:(Printf.sprintf "3 %d" (T.compare (u "AB") (u "ABCDEF")))
    true (T.compare (u "AB") (u "ABCDEF") < 0)

let test_t_get () =
  let u = T.of_string_exn in
  let t = u "abcdef" in
  assert_equal ~msg:"a" 'a' (UChar.char_of (T.get_exn t 0));
  assert_equal ~msg:"b" 'b' (UChar.char_of (T.get_exn t 1));
  assert_equal ~msg:"c" 'c' (UChar.char_of (T.get_exn t 2));
  assert_equal ~msg:"d" 'd' (UChar.char_of (T.get_exn t 3));
  assert_equal ~msg:"e" 'e' (UChar.char_of (T.get_exn t 4));
  assert_equal ~msg:"f" 'f' (UChar.char_of (T.get_exn t 5));
  assert_equal ~msg:"None" None (T.get t 6)

let cycle = [| 'a'; 'b'; 'c'; 'd'; 'e' |]

let large_t = 
  let r = ref T.empty in
  let b = Buffer.create 0 in
  for i = 0 to large_num do
    let m = i mod 5 in
    r := T.append_uchar !r (UChar.of_char cycle.(m));
  done;
  !r

let test_t_get_large () =
  for i = 0 to large_num do
    let m = i mod 5 in
    let c = UChar.char_of (T.get_exn large_t i) in
    assert_equal ~msg:(Printf.sprintf "%d %c %c" i cycle.(m) c) cycle.(m) c
  done

let test_t_first () =
  let it = T.first large_t in
  assert_equal 'a' (UChar.char_of (T.value it))
  
let test_t_last () =
  let it = T.last large_t in
  assert_equal cycle.(large_num mod 5) (UChar.char_of (T.value it))

let test_t_nth () =
  for i = 0 to large_num do
    let it = T.nth_exn large_t i in
    assert_equal cycle.(i mod 5) (UChar.char_of (T.value it))
  done;
  assert_equal None (T.nth large_t (1+ large_num))

let test_t_next () =
  let rit = ref (T.first large_t) in
  for i = 0 to large_num do
    let expected = cycle.(i mod 5) in
    let result = UChar.char_of (T.value !rit) in
    assert_equal ~msg:(Printf.sprintf "loc:%d, %s != %s" 
			 i (Char.escaped expected) (Char.escaped result))
			 expected result;
    match T.next !rit with
      None -> assert_equal ~msg:"Expected None." large_num i
    | Some it -> rit := it;
  done

let test_t_prev () =
  let rit = ref (T.last large_t) in
  for i = 0 to large_num do
    let expected = cycle.((large_num - i) mod 5) in
    let result = UChar.char_of (T.value !rit) in
    assert_equal ~msg:(Printf.sprintf "loc:%d, %s != %s" 
			 (large_num - i) 
			 (Char.escaped expected) (Char.escaped result))
			 expected result;
    match T.prev !rit with
      None -> assert_equal ~msg:"Expected None." large_num i
    | Some it -> rit := it;
  done

let test_t_value () =
  let u = T.of_string_exn in
  let t = u "abcdef" in
  let it = T.first t in
  assert_equal ~msg:"a" 'a' (UChar.char_of (T.value it));
  let it = T.next_exn it in
  assert_equal ~msg:"b" 'b' (UChar.char_of (T.value it));
  let it = T.next_exn it in
  assert_equal ~msg:"c" 'c' (UChar.char_of (T.value it));
  let it = T.next_exn it in
  assert_equal ~msg:"d" 'd' (UChar.char_of (T.value it));
  let it = T.next_exn it in
  assert_equal ~msg:"e" 'e' (UChar.char_of (T.value it));
  let it = T.next_exn it in
  assert_equal ~msg:"f" 'f' (UChar.char_of (T.value it));
  assert_equal ~msg:"None" None (T.next it)

let test_t_base () =
  let u = T.of_string_exn in
  let t = u "abcdef" in
  let it = T.first t in
  assert_equal true (T.compare t (T.base it) = 0)

let test_t_pos () =
  let u = T.of_string_exn in
  let t = u "abcdef" in
  let it = T.first t in
  let it = T.next_exn (T.next_exn (T.next_exn it)) in
  assert_equal 3 (T.pos it)

let test_t_insert () =
  let u = T.of_string_exn in
  let t = u "abcdef" in
  let t = T.insert_exn t 3 (u "ggg") in
  assert_equal ~msg:(T.string_of t) "abcgggdef" (T.string_of t)

let test_t_delete () =
  let u = T.of_string_exn in
  let t = u "abcgggdef" in
  let t = T.delete t ~pos:3 ~len:3 in
  assert_equal ~msg:(T.string_of t) "abcdef" (T.string_of t)

let test_t_sub () =
  let u = T.of_string_exn in
  let t = u "abcgggdef" in
  let t = T.sub t ~pos:3 ~len:3 in
  assert_equal ~msg:(T.string_of t) "ggg" (T.string_of t)

let test_t_fold () =
  let u = T.of_string_exn in
  let t = u "abcgggdef" in
  let search_max u0 u =
    if UChar.compare u0 u >= 0 then u0 else u in
  assert_equal (UChar.of_char 'g') (T.fold t (UChar.chr 0) search_max)

(* CharEncoding *)

let test_enc_uchar enc u =
  let t = Text.of_uchar u in
  match CharEncoding.encode_text enc t with
    `Error -> assert_failure (Printf.sprintf "Encoding Error:%08x" 
				(UChar.int_of u));
  |`Success s ->
      let t' = CharEncoding.decode_string enc s in
      assert_equal ~msg:(Printf.sprintf "char:%8x" (UChar.int_of u)) 
	(Text.compare t t') 0
      
let random_ascii () =
  let s = String.create (Random.int 1000) in
  for i = 0 to String.length s - 1 do
    s.[i] <- Char.chr (Random.int 0x80)
  done;
  s
 
let test_ascii_valid () =
  for i = 0 to 100 do
    let s = random_ascii () in
    assert_equal 
      (`Success s)
      (CharEncoding.recode CharEncoding.ascii s CharEncoding.ascii) 
  done

let test_ascii_invalid () =
  for i = 0 to 100 do
    let s = random_string () in
    let t = CharEncoding.decode_string CharEncoding.ascii s in

    (* test for length *)
    let len = Text.length t in
    assert_equal len (String.length s);

    (* indexing *)
    for i = 0 to String.length s - 1 do
      if Char.code s.[i]  < 0x80 then
        assert_equal (UChar.code (Text.get_exn t i)) (Char.code s.[i])
      else
        assert_equal (UChar.code (Text.get_exn t i)) 0xfffd
    done;
  done

let test_ascii_repl () =
  let t = Text.of_uchar (UChar.chr 0x1000) in
  assert_equal (`Success "\u1000")
    (CharEncoding.encode_text ~repl:CharEncoding.repl_escape CharEncoding.ascii t)  


let random_latin1 () =
  let s = String.create (Random.int 1000) in
  for i = 0 to String.length s - 1 do
    s.[i] <- Char.chr (Random.int 0x100)
  done;
  s
 
let test_latin1_valid () =
  for i = 0 to 100 do
    let s = random_latin1 () in
    assert_equal 
      (`Success s)
      (CharEncoding.recode CharEncoding.latin1 s CharEncoding.latin1) 
  done

let test_latin1_repl () =
  let t = Text.of_uchar (UChar.chr 0x1000) in
  assert_equal (`Success "\u1000")
    (CharEncoding.encode_text ~repl:CharEncoding.repl_escape CharEncoding.latin1 t)  

let random_text_list n = 
  let a = Array.init (Random.int 10) (fun _ -> random_text n) in
  Array.to_list a
  
let test_utf_random_text enc n =
  let text = random_text n in
  let s = match CharEncoding.encode_text enc text with
    `Success s -> s
  | `Error -> assert_failure (Printf.sprintf "Encoding Error:%s" 
				(String.escaped (Text.string_of text))) in
  let text' = CharEncoding.decode_string enc s in
  assert_equal 
        ~msg:(Printf.sprintf "\n%s !=\n%s\n %d %s" (sprint_text text) (sprint_text text') (Text.compare text text') (String.escaped s))
    (Text.compare text text') 0

let test_utf8_random n = test_utf_random_text CharEncoding.utf8 n

let chop n s =
  let n = if n > String.length s then String.length s else n in
  let s0 = String.sub s 0 n in
  let s1 = String.sub s n (String.length s - n) in
  (s0, s1)

let test_utf_random_text_list enc n =
  let text = random_text n in
  let s = match CharEncoding.encode_text enc text with
    `Success s -> s
  | `Error -> assert_failure "Encoding Error" in
  let decoder = CharEncoding.create_decoder enc in
  let rec loop decoder s t =
    if s = "" then Text.append t (CharEncoding.terminate_decoder decoder) else
    let s0, s1 = chop 1 s in
    let decoder, t' = CharEncoding.decode decoder s0 in
    loop decoder s1 (Text.append t t') in
  let text' = loop decoder s Text.empty in
  assert_equal 
    ~msg:(Printf.sprintf "\n%s !=\n%s\n %s" (sprint_text text) (sprint_text text') (sprint_string s))
    (Text.compare text text') 0
 
let test_utf8_random_list n = test_utf_random_text_list CharEncoding.utf8 n

let test_decode_valid_utf8 (name, s, clist) =
  let test () =
    let text = CharEncoding.decode_string CharEncoding.utf8 s in
    for i = 0 to List.length clist - 1 do
      let u = Text.get_exn text i in
      let n = List.nth clist i in
      assert_equal ~msg:(Printf.sprintf "character %x != %x" n (UChar.code u)) u  (UChar.chr n);      
    done;
  in
  ("valid string: " ^ name) >:: test

let contains text u0 = T.fold text false (fun b u ->
  if b then true else
  if UChar.eq u0 u then true else false)

let test_decode_invalid_utf8 s =
  ("invalid string:" ^ (String.escaped s)) >:: 
    (fun () ->
      let text = CharEncoding.decode_string CharEncoding.utf8 s in
      assert_bool s (contains text (UChar.chr 0xfffd)))

(* UTF-16 *)
let test_utf16be_uchar () =
  test_enc_uchar CharEncoding.utf16be (UChar.of_int 0);
  test_enc_uchar CharEncoding.utf16be (UChar.of_int 0xA000);
  test_enc_uchar CharEncoding.utf16be (UChar.of_int 0xFFFD);
  test_enc_uchar CharEncoding.utf16be (UChar.of_int 0x10000);
  test_enc_uchar CharEncoding.utf16be (UChar.of_int 0x10FFFF)

let test_utf16be_invalid_string () =
  let s = "\xd8\x00\xdc\x00\xdc\x10\x00" in
  let t = CharEncoding.decode_string CharEncoding.utf16be s in
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 0)) (0x10000);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 1)) (0xfffd);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 2)) (0x1000)

let test_utf16be_random n = test_utf_random_text CharEncoding.utf16be n
let test_utf16be_random_list n = test_utf_random_text_list CharEncoding.utf16be n

let test_utf16le_uchar () =
  test_enc_uchar CharEncoding.utf16le (UChar.of_int 0);
  test_enc_uchar CharEncoding.utf16le (UChar.of_int 0xA000);
  test_enc_uchar CharEncoding.utf16le (UChar.of_int 0xFFFD);
  test_enc_uchar CharEncoding.utf16le (UChar.of_int 0x10000);
  test_enc_uchar CharEncoding.utf16le (UChar.of_int 0x10FFFF)

let test_utf16le_invalid_string () =
  let s = "\x00\xd8\x00\xdc\x00\xdc\x10\x00" in
  let t = CharEncoding.decode_string CharEncoding.utf16le s in
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 0)) (0x10000);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 1)) (0xfffd);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 2)) (0x10dc);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 3)) (0xfffd)

let test_utf16le_random n = test_utf_random_text CharEncoding.utf16le n
let test_utf16le_random_list n = test_utf_random_text_list CharEncoding.utf16le n


let test_utf16_uchar () =
  test_enc_uchar CharEncoding.utf16 (UChar.of_int 0);
  test_enc_uchar CharEncoding.utf16 (UChar.of_int 0xA000);
  test_enc_uchar CharEncoding.utf16 (UChar.of_int 0xFFFD);
  test_enc_uchar CharEncoding.utf16 (UChar.of_int 0x10000);
  test_enc_uchar CharEncoding.utf16 (UChar.of_int 0x10FFFF)

let test_utf16_invalid_string_be () =
  let s = "\xfe\xff\xd8\x00\xdc\x00\xdc\x10\x00" in
  let t = CharEncoding.decode_string CharEncoding.utf16 s in
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 0)) (0x10000);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 1)) (0xfffd);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 2)) (0x1000)

let test_utf16_invalid_string_le () =
  let s =  "\xff\xfe\x00\xd8\x00\xdc\x10\xdc\x00" in
  let t = CharEncoding.decode_string CharEncoding.utf16 s in
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 0)) (0x10000);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 1)) (0xfffd);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 2)) (0x00dc)

let test_utf16_invalid_string_default () =
  let s = "\xd8\x00\xdc\x00\xdc\x10\x00" in
  let t = CharEncoding.decode_string CharEncoding.utf16 s in
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 0)) (0x10000);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 1)) (0xfffd);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 2)) (0x1000)


let test_utf16_random n = test_utf_random_text CharEncoding.utf16 n
let test_utf16_random_list n = test_utf_random_text_list CharEncoding.utf16 n

(* UTF-32 *)
let test_utf32be_uchar () =
  test_enc_uchar CharEncoding.utf32be (UChar.of_int 0);
  test_enc_uchar CharEncoding.utf32be (UChar.of_int 0xA000);
  test_enc_uchar CharEncoding.utf32be (UChar.of_int 0xFFFD);
  test_enc_uchar CharEncoding.utf32be (UChar.of_int 0x10000);
  test_enc_uchar CharEncoding.utf32be (UChar.of_int 0x10FFFF)

let test_utf32be_invalid_string () =
  let s = "\x00\x01\x00\x00\x01\x00\x01\x00\x00" in
  let t = CharEncoding.decode_string CharEncoding.utf32be s in
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 0)) (0x10000);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 1)) (0xfffd);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 2)) (0x10000)

let test_utf32be_random n = test_utf_random_text CharEncoding.utf32be n
let test_utf32be_random_list n = test_utf_random_text_list CharEncoding.utf32be n

let test_utf32le_uchar () =
  test_enc_uchar CharEncoding.utf32le (UChar.of_int 0);
  test_enc_uchar CharEncoding.utf32le (UChar.of_int 0xA000);
  test_enc_uchar CharEncoding.utf32le (UChar.of_int 0xFFFD);
  test_enc_uchar CharEncoding.utf32le (UChar.of_int 0x10000);
  test_enc_uchar CharEncoding.utf32le (UChar.of_int 0x10FFFF)

let test_utf32le_invalid_string () =
  let s = "\x00\x00\x01\x00\x00\x01\x00\x01\x00" in
  let t = CharEncoding.decode_string CharEncoding.utf32le s in
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 0)) (0x10000);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 1)) (0xfffd)

let test_utf32le_random n = test_utf_random_text CharEncoding.utf32le n
let test_utf32le_random_list n = test_utf_random_text_list CharEncoding.utf32le n


let test_utf32_uchar () =
  test_enc_uchar CharEncoding.utf32 (UChar.of_int 0);
  test_enc_uchar CharEncoding.utf32 (UChar.of_int 0xA000);
  test_enc_uchar CharEncoding.utf32 (UChar.of_int 0xFFFD);
  test_enc_uchar CharEncoding.utf32 (UChar.of_int 0x10000);
  test_enc_uchar CharEncoding.utf32 (UChar.of_int 0x10FFFF)

let test_utf32_invalid_string_be () =
  let s = "\x00\x00\xfe\xff\x00\x01\x00\x00\x01\x00\x00\x10\x00" in
  let t = CharEncoding.decode_string CharEncoding.utf32 s in
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 0)) (0x10000);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 1)) (0xfffd);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 2)) (0x1000)

let test_utf32_invalid_string_le () =
  let s = "\xff\xfe\x00\x00\x00\x00\x01\x00\x01\x00\x01\x00\x00" in
  let t = CharEncoding.decode_string CharEncoding.utf32 s in
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 0)) (0x10000);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 1)) (0x010001);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 2)) (0xfffd)

let test_utf32_invalid_string_default () =
  let s = "\x00\x01\x00\x00\x01\x00\x00\x10\x00" in
  let t = CharEncoding.decode_string CharEncoding.utf32 s in
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 0)) (0x10000);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 1)) (0xfffd);
  assert_equal ~msg:(sprint_text t) (UChar.code (Text.get_exn t 2)) (0x1000)


let test_utf32_random n = test_utf_random_text CharEncoding.utf32 n
let test_utf32_random_list n = test_utf_random_text_list CharEncoding.utf32 n


let suite = 
  "ucorelib test" >:::
    [ "test UChar" >:::
        ["chr<->uchar" >:::
            ["uchar<-char" >:: test_char1;
             "char<-uchar" >:: test_char2];
         "uchar<->code" >:: test_int_uchar;
         "test_uchar_eq" >:: test_uchar_eq;
         "test_uchar_compare" >:: test_uchar_compare];
     "test Text'" >::: 
       ["random test" >:: test_t_random;
        "empty" >:: test_t_empty;
	"length" >:: test_t_length;
	"init" >:: test_t_init;
	"of_uchar" >:: test_t_of_uchar;
	"of_string:random" >:: test_t_of_string_random;
        "of_srting:valid" >::: (List.map test_t_of_string_valid_utf8 utf8_valid_pairs);
        "of_string:invalid" >::: (List.map test_t_of_string_invalid_utf8 utf8_brokens);
	"string_of" >:: test_t_string_of;
	"of_ascii" >:: test_t_of_ascii;
	"of_latin1" >:: test_t_of_latin1;
	"append" >:: test_t_append;
	"append list" >:: test_t_append_random_list 10;
	"append_uchar" >:: test_t_append_uchar;
	"append_uchar_large" >:: test_t_append_uchar_large;
	"append_uchar_random" >:: test_t_append_random_uchar 100;
	"compare" >:: test_t_compare;
	"get" >:: test_t_get;
	"get large" >:: test_t_get_large;
	"first" >:: test_t_first;
	"last" >:: test_t_last;
	"nth" >:: test_t_nth;
	"next" >:: test_t_next;
	"prev" >:: test_t_prev;
	"value" >:: test_t_value;
	"base" >:: test_t_base;
	"pos" >:: test_t_pos;
	"insert" >:: test_t_insert;
	"delete" >:: test_t_delete;
	"sub" >:: test_t_sub;
	"fold" >:: test_t_fold;
      ];
     "test Character Encodings" >:::
       [ "test ascii valid" >:: test_ascii_valid;
        "test ascii invalid" >:: test_ascii_invalid;
        "test ascii repl" >:: test_ascii_repl;
        "test latin1 valid" >:: test_latin1_valid;
        "test latin1 repl" >:: test_latin1_repl;
        "test utf8 random text: 10" >:: (fun () -> test_utf8_random 10);
        "test utf8 random text: 100" >:: (fun () -> test_utf8_random 100);
        "test utf8 random text list: 10" >:: (fun () -> test_utf8_random_list 10);
        "test utf8 random text list: 100" >:: (fun () -> test_utf8_random_list 100);
        "valid strings" >::: (List.map test_decode_valid_utf8 utf8_valid_pairs);
        "invalid strings" >::: (List.map test_decode_invalid_utf8 utf8_brokens);
        "test utf16be random uchar" >:: test_utf16be_uchar;
	"test utf16be invalid string" >:: test_utf16be_invalid_string;
        "test utf16be random text: 10" >:: (fun () -> test_utf16be_random 10);
        "test utf16be random text: 100" >:: (fun () -> test_utf16be_random 100);
        "test utf16be random text list: 10" >:: (fun () -> test_utf16be_random_list 10);
        "test utf16be random text list: 100" >:: (fun () -> test_utf16be_random_list 100);
        "test utf16le random uchar" >:: test_utf16le_uchar;
	"test utf16le invalid string" >:: test_utf16le_invalid_string;
        "test utf16le random text: 10" >:: (fun () -> test_utf16le_random 10);
        "test utf16le random text: 100" >:: (fun () -> test_utf16le_random 100);
        "test utf16le random text list: 10" >:: (fun () -> test_utf16le_random_list 10);
        "test utf16le random text list: 100" >:: (fun () -> test_utf16le_random_list 100);
        "test utf16 random uchar" >:: test_utf16_uchar;
	"test utf16 invalid be string" >:: test_utf16_invalid_string_be;
	"test utf16 invalid le string" >:: test_utf16_invalid_string_le;
	"test utf16 invalid default string" >:: test_utf16_invalid_string_default;
        "test utf16 random text: 10" >:: (fun () -> test_utf16_random 10);
        "test utf16 random text: 100" >:: (fun () -> test_utf16_random 100);
        "test utf16 random text list: 10" >:: (fun () -> test_utf16_random_list 10);
        "test utf16 random text list: 100" >:: (fun () -> test_utf16_random_list 100);
        "test utf32be random uchar" >:: test_utf32be_uchar;
	"test utf32be invalid string" >:: test_utf32be_invalid_string;
        "test utf32be random text: 10" >:: (fun () -> test_utf32be_random 10);
        "test utf32be random text: 100" >:: (fun () -> test_utf32be_random 100);
        "test utf32be random text list: 10" >:: (fun () -> test_utf32be_random_list 10);
         "test utf32be random text list: 100" >:: (fun () -> test_utf32be_random_list 100);
        "test utf32le random uchar" >:: test_utf32le_uchar;
	"test utf32le invalid string" >:: test_utf32le_invalid_string;
        "test utf32le random text: 10" >:: (fun () -> test_utf32le_random 10);
        "test utf32le random text: 100" >:: (fun () -> test_utf32le_random 100);
        "test utf32le random text list: 10" >:: (fun () -> test_utf32le_random_list 10);
        "test utf32le random text list: 100" >:: (fun () -> test_utf32le_random_list 100);
        "test utf32 random uchar" >:: test_utf32_uchar;
	"test utf32 invalid be string" >:: test_utf32_invalid_string_be;
	"test utf32 invalid le string" >:: test_utf32_invalid_string_le; 
	"test utf32 invalid default string" >:: test_utf32_invalid_string_default;
        "test utf32 random text: 10" >:: (fun () -> test_utf32_random 10);
        "test utf32 random text: 100" >:: (fun () -> test_utf32_random 100);
        "test utf32 random text list: 10" >:: (fun () -> test_utf32_random_list 10);
         "test utf32 random text list: 100" >:: (fun () -> test_utf32_random_list 100);
       ]
    ]

let () = OUnit2.run_test_tt_main (ounit2_of_ounit1 suite)


