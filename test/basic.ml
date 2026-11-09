let expect ~here ~expected s =
  if String.equal expected s then ()
  else (
    Printf.eprintf "%s\n" here;
    Printf.eprintf "Expected: %s\nReceived: %s\n" expected s;
    exit 2)

let () =
  let s, () =
    Out_channel_redirect.capture_outputs_interleaved ~f:(fun () ->
        Printf.printf "printf%!";
        Printf.eprintf "eprintf%!")
  in
  expect ~here:__LOC__ ~expected:"printfeprintf" s

let () =
  let s, inner =
    Out_channel_redirect.capture_outputs_interleaved ~f:(fun () ->
        let (inner : string), () =
          Out_channel_redirect.capture_stdout ~f:(fun () ->
              Printf.printf "printf%!";
              Printf.eprintf "eprintf%!")
        in
        inner)
  in
  expect ~here:__LOC__ ~expected:"eprintf" s;
  expect ~here:__LOC__ ~expected:"printf" inner

let () =
  let s, inner =
    Out_channel_redirect.capture_outputs_interleaved ~f:(fun () ->
        let (inner : string), () =
          Out_channel_redirect.capture_stderr ~f:(fun () ->
              Printf.printf "printf%!";
              Printf.eprintf "eprintf%!")
        in
        inner)
  in
  expect ~here:__LOC__ ~expected:"printf" s;
  expect ~here:__LOC__ ~expected:"eprintf" inner

let () =
  let s1, (s2, (s3, ())) =
    Out_channel_redirect.capture_stderr ~f:(fun () ->
        Out_channel_redirect.capture_stderr ~f:(fun () ->
            Out_channel_redirect.capture_stderr ~f:(fun () ->
                Printf.eprintf "HERE%!")))
  in
  expect ~here:__LOC__ ~expected:"" s1;
  expect ~here:__LOC__ ~expected:"" s2;
  expect ~here:__LOC__ ~expected:"HERE" s3

let () =
  let s1, () =
    Out_channel_redirect.capture_stderr ~f:(fun () ->
        let s, () =
          Out_channel_redirect.capture_stderr ~f:(fun () ->
              let s, () =
                Out_channel_redirect.capture_stderr ~f:(fun () ->
                    Printf.eprintf "HERE%!")
              in
              Printf.eprintf "%s%!" s)
        in
        Printf.eprintf "%s%!" s)
  in
  expect ~here:__LOC__ ~expected:"HERE" s1

let () =
  let s, () =
    Out_channel_redirect.capture_stdout ~f:(fun () ->
        Out_channel_redirect.redirect stderr ~into:stdout ~f:(fun () ->
            Printf.eprintf "HERE%!"))
  in
  expect ~here:__LOC__ ~expected:"HERE" s

let () =
  let s, () =
    Out_channel_redirect.redirect stderr ~into:stdout ~f:(fun () ->
        Out_channel_redirect.capture_stderr ~f:(fun () ->
            Printf.eprintf "HERE%!"))
  in
  expect ~here:__LOC__ ~expected:"HERE" s

let () =
  let s1, s2 =
    Out_channel_redirect.capture_stdout ~f:(fun () ->
        let s, () =
          Out_channel_redirect.redirect stderr ~into:stdout ~f:(fun () ->
              Out_channel_redirect.capture_stdout ~f:(fun () ->
                  Printf.eprintf "HERE%!"))
        in
        s)
  in
  expect ~here:__LOC__ ~expected:"HERE" s1;
  expect ~here:__LOC__ ~expected:"" s2

let () =
  let s, () =
    Out_channel_redirect.capture_outputs_interleaved ~f:(fun () ->
        Out_channel_redirect_test_helper.out_channel_redirect_print_stdout ())
  in
  expect ~here:__LOC__ ~expected:"stdout from external" s

let () =
  let s, () =
    Out_channel_redirect.capture_outputs_interleaved ~f:(fun () ->
        Out_channel_redirect_test_helper.out_channel_redirect_print_stderr ())
  in
  expect ~here:__LOC__ ~expected:"stderr from external" s

(* Exception safety: capture_stdout restores channel on exception *)
let () =
  (try
     ignore
       (Out_channel_redirect.capture_stdout ~f:(fun () ->
            Printf.printf "before%!";
            failwith "test exception"))
   with Failure _ -> ());
  let s, () =
    Out_channel_redirect.capture_stdout ~f:(fun () -> Printf.printf "after%!")
  in
  expect ~here:__LOC__ ~expected:"after" s

(* Exception safety: capture_stderr restores channel on exception *)
let () =
  (try
     ignore
       (Out_channel_redirect.capture_stderr ~f:(fun () ->
            Printf.eprintf "before%!";
            failwith "test exception"))
   with Failure _ -> ());
  let s, () =
    Out_channel_redirect.capture_stderr ~f:(fun () -> Printf.eprintf "after%!")
  in
  expect ~here:__LOC__ ~expected:"after" s

(* Exception safety: capture_outputs_interleaved restores both channels on exception *)
let () =
  (try
     ignore
       (Out_channel_redirect.capture_outputs_interleaved ~f:(fun () ->
            Printf.printf "before%!";
            Printf.eprintf "before%!";
            failwith "test exception"))
   with Failure _ -> ());
  let s, () =
    Out_channel_redirect.capture_outputs_interleaved ~f:(fun () ->
        Printf.printf "stdout%!";
        Printf.eprintf "stderr%!")
  in
  expect ~here:__LOC__ ~expected:"stdoutstderr" s

(* Expert.stop idempotency: calling stop twice should not crash *)
let () =
  let s, () =
    Out_channel_redirect.capture_stdout ~f:(fun () ->
        let redir = Out_channel_redirect.Expert.redirect ~into:stdout stderr in
        Printf.eprintf "redirected%!";
        Out_channel_redirect.Expert.stop redir;
        Out_channel_redirect.Expert.stop redir)
  in
  expect ~here:__LOC__ ~expected:"redirected" s

(* capture_channel called directly with stdout *)
let () =
  let s, () =
    Out_channel_redirect.capture_channel stdout ~f:(fun () ->
        Printf.printf "direct channel%!")
  in
  expect ~here:__LOC__ ~expected:"direct channel" s

(* capture_channel called directly with stderr *)
let () =
  let s, () =
    Out_channel_redirect.capture_channel stderr ~f:(fun () ->
        Printf.eprintf "direct stderr%!")
  in
  expect ~here:__LOC__ ~expected:"direct stderr" s

(* Large output: exceed typical buffer sizes *)
let () =
  let big = String.make 100_000 'x' in
  let s, () =
    Out_channel_redirect.capture_stdout ~f:(fun () ->
        print_string big;
        flush stdout)
  in
  expect ~here:__LOC__ ~expected:big s

(* capture_channels returns one string per channel *)
let () =
  let xs, () =
    Out_channel_redirect.capture_channels [ stdout; stderr ] ~f:(fun () ->
        Printf.printf "out%!";
        Printf.eprintf "err%!")
  in
  match xs with
  | [ out; err ] ->
      expect ~here:__LOC__ ~expected:"out" out;
      expect ~here:__LOC__ ~expected:"err" err
  | _ -> assert false

(* capture_channels with an empty list just runs f *)
let () =
  let xs, n = Out_channel_redirect.capture_channels [] ~f:(fun () -> 42) in
  assert (xs = []);
  assert (n = 42)

(* capture_channels_interleaved flushes channels in list order at the
   end of [f]. On Native/Bytecode each channel keeps its own buffer, so
   the list order determines which buffer reaches the capture file first.
   On JS/Wasm the redirect swaps the entire channel object: writes to any
   listed channel go into the proxy's buffer in call order, regardless of
   list order. *)
let () =
  let tmp1, c1 = Filename.open_temp_file "test-" "" in
  let tmp2, c2 = Filename.open_temp_file "test-" "" in
  let s_a_then_b, () =
    Out_channel_redirect.capture_channels_interleaved [ c1; c2 ] ~f:(fun () ->
        output_string c1 "a";
        output_string c2 "b")
  in
  expect ~here:__LOC__ ~expected:"ab" s_a_then_b;
  let s_b_then_a, () =
    Out_channel_redirect.capture_channels_interleaved [ c2; c1 ] ~f:(fun () ->
        output_string c1 "a";
        output_string c2 "b")
  in
  (match Sys.backend_type with
  | Native | Bytecode | Other "wasm_of_ocaml" ->
      expect ~here:__LOC__ ~expected:"ba" s_b_then_a
  | Other _ -> expect ~here:__LOC__ ~expected:"ab" s_b_then_a);
  close_out_noerr c1;
  close_out_noerr c2;
  Sys.remove tmp1;
  Sys.remove tmp2

(* capture_channels_interleaved merges output from several channels in
   write order *)
let () =
  let s, () =
    Out_channel_redirect.capture_channels_interleaved [ stdout; stderr ]
      ~f:(fun () ->
        Printf.printf "1%!";
        Printf.eprintf "2%!";
        Printf.printf "3%!")
  in
  expect ~here:__LOC__ ~expected:"123" s

(* capture_channels with a channel duplicated in the list: the innermost
   redirection wins, earlier entries capture nothing *)
let () =
  let xs, () =
    Out_channel_redirect.capture_channels [ stdout; stdout ] ~f:(fun () ->
        Printf.printf "hello%!")
  in
  match xs with
  | [ a; b ] ->
      expect ~here:__LOC__ ~expected:"" a;
      expect ~here:__LOC__ ~expected:"hello" b
  | _ -> assert false

(* capture_channels_interleaved with a duplicated channel: output appears
   once *)
let () =
  let s, () =
    Out_channel_redirect.capture_channels_interleaved [ stdout; stdout ]
      ~f:(fun () -> Printf.printf "hello%!")
  in
  expect ~here:__LOC__ ~expected:"hello" s

(* capture_outputs returns stdout and stderr separately *)
let () =
  let out, err, () =
    Out_channel_redirect.capture_outputs ~f:(fun () ->
        Printf.printf "to-stdout%!";
        Printf.eprintf "to-stderr%!")
  in
  expect ~here:__LOC__ ~expected:"to-stdout" out;
  expect ~here:__LOC__ ~expected:"to-stderr" err

(* Exception safety: capture_outputs restores both channels on exception *)
let () =
  (try
     ignore
       (Out_channel_redirect.capture_outputs ~f:(fun () ->
            Printf.printf "before%!";
            Printf.eprintf "before%!";
            failwith "test exception"))
   with Failure _ -> ());
  let s, () =
    Out_channel_redirect.capture_outputs_interleaved ~f:(fun () ->
        Printf.printf "stdout%!";
        Printf.eprintf "stderr%!")
  in
  expect ~here:__LOC__ ~expected:"stdoutstderr" s

(* Exception safety: capture_channel' restores on exception *)
let () =
  let _, () =
    Out_channel_redirect.capture_stdout ~f:(fun () ->
        try
          Out_channel_redirect.redirect stderr ~into:stdout ~f:(fun () ->
              Printf.eprintf "before%!";
              failwith "test exception")
        with Failure _ -> ())
  in
  let s, () =
    Out_channel_redirect.capture_stderr ~f:(fun () ->
        Printf.eprintf "restored%!")
  in
  expect ~here:__LOC__ ~expected:"restored" s

(* On Windows, handles cached from the standard fds before any redirection
   (as [Unix.stdout] and [Unix.stderr] do) must remain valid, both during and
   after a capture. *)
let () =
  let check ~here =
    if not (Out_channel_redirect_test_helper.std_handles_valid ()) then (
      Printf.eprintf "%s\nstandard handles were invalidated\n" here;
      exit 2)
  in
  for _ = 1 to 10 do
    let _, _, () =
      Out_channel_redirect.capture_outputs ~f:(fun () ->
          check ~here:__LOC__;
          let _, () =
            Out_channel_redirect.capture_stdout ~f:(fun () ->
                check ~here:__LOC__)
          in
          check ~here:__LOC__)
    in
    check ~here:__LOC__
  done
