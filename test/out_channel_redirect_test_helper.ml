external init_channels : out_channel -> out_channel -> unit
  = "out_channel_redirect_init_channels"

let () = init_channels stdout stderr

external out_channel_redirect_print_stdout : unit -> unit
  = "out_channel_redirect_print_stdout"

external out_channel_redirect_print_stderr : unit -> unit
  = "out_channel_redirect_print_stderr"

external std_handles_valid : unit -> bool
  = "out_channel_redirect_std_handles_valid"
