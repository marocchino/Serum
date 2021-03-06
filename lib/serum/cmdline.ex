defmodule Serum.Cmdline do
  @moduledoc """
  This module contains the entry point for the command line program
  (`Serum.Cmdline.main/1`).
  """

  alias Serum.Error
  alias Serum.Init
  alias Serum.Build
  alias Serum.DevServer

  @opt_build    [parallel: :boolean, output: :string]
  @opt_server   [port: :integer]
  @alias_build  [p: :parallel, o: :output]
  @alias_server [p: :port]

  @doc """
  The entry point for Serum command-line program.
  """
  @spec main(args :: [String.t]) :: any
  def main(args) do
    info
    [task|opts] = args
    case task do
      "version" -> :nop
      "init"    -> cmd_init(opts)
      "build"   -> cmd_build(opts)
      "server"  -> cmd_server(opts)
      "help"    -> usage
      _         -> usage
    end
  end

  @spec info() :: :ok
  defp info() do
    IO.puts "\x1b[1mSerum -- Yet another simple static website generator"
    IO.puts "Version 0.9.0. Copyright (C) 2016 Dalgona. <dalgona@hontou.moe>\x1b[0m\n"
  end

  @spec cmd_init([String.t]) :: :ok
  defp cmd_init([]),      do: Init.init(".")
  defp cmd_init([dir|_]), do: Init.init(dir)

  @spec cmd_build([String.t]) :: Serum.Error.result
  defp cmd_build(cmd) do
    {opts, args, errors} =
      OptionParser.parse(cmd, strict: @opt_build, aliases: @alias_build)
    mode = Keyword.get(opts, :parallel) && :parallel || :sequential
    out = Keyword.get(opts, :output)
    case {args, errors} do
      {args, []}  -> launch_build(args, out, mode)
      {_, _error} -> usage
    end
  end

  @spec cmd_server([String.t]) :: any
  defp cmd_server(cmd) do
    {opts, args, errors} =
      OptionParser.parse(cmd, strict: @opt_server, aliases: @alias_server)
    port = Keyword.get(opts, :port) || 8080
    case {args, errors} do
      {[], []}      -> DevServer.run(".", port)
      {[dir|_], []} -> DevServer.run(dir, port)
      {_, _error}   -> usage
    end
  end

  @spec launch_build([String.t], String.t, Build.build_mode) :: any
  defp launch_build(args, out, mode) do
    dir =
      case args do
        []      -> "."
        [dir|_] -> dir
      end
    case Build.build(dir, out, mode) do
      {:ok, dest} ->
        finish_build(dest)
      error = {:error, _, _} ->
        error_build(error)
    end
  end

  @spec usage() :: :ok
  defp usage() do
    IO.puts """
    Usage: serum <task>

      Available Tasks:
      \x1b[96minit\x1b[0m [dir]               Initializes a new Serum project

      \x1b[96mbuild\x1b[0m [options] [dir]    Builds an existing Serum project
        dir                    (optional) Path to a Serum project
        -p, --parallel         Builds the pages parallelly
        -o, --output <outdir>  Specifies the output directory

      \x1b[96mserver\x1b[0m [options] [dir]   Starts a web server
        dir                    (optional) Path to a Serum project
        -p, --port             Specifies HTTP port the server listens on
                               (Default is 8080)

      \x1b[96mhelp\x1b[0m                     Shows this help message

      \x1b[96mversion\x1b[0m                  Shows the version information
    """
  end

  @spec finish_build(String.t) :: :ok
  defp finish_build(dest) do
    IO.puts """

    \x1b[1mYour website is now ready!
    Copy(move) the contents of `#{dest}` directory
    into your public webpages directory.\x1b[0m
    """
  end

  @spec error_build(Error.error) :: :ok
  defp error_build(error) do
    Error.show(error)
    IO.puts """

    Could not build the website due to error(s).
    Please fix the problems shown above and try again.
    """
  end
end
