#! /usr/bin/env elixir


defmodule CommandLineParser do
  @moduledoc """
  This module parses the command line argument using OptionsParser.
  The default argument are the CWD from which the script is invoked (or /tmp), and port number of 8080.
  """

  @script_name __ENV__.file

  # The default arguments
  defp default_args() do
    case File.cwd() do
      {:ok, cwd} -> %{book: cwd, port: 8080, stop: false}
      _ ->  %{book: '/tmp', port: 8080, stop: false}
    end
  end

  @doc """
  Receive the arguments from command line and returned the parsed output as a map {book: :string, port: :integer}
  """
  def parse(args) do
    {arg_list, _,_} = OptionParser.parse(args, strict: [
      book: :string,
      port: :integer,
      stop: :boolean,
    ])

    parsed_args = Map.merge(default_args(), Map.new(arg_list))

    case validate_args(parsed_args) do
      {:ok, _ } -> {:ok, parsed_args}
      {:error, err_msg} -> {:error, err_msg}
      _ -> {:error, "Error"}
    end
  end

  # Return ok if the book path is a directory and port number is larger than 1024.
  defp validate_args(parsed_args) do
    cond do
      File.dir?(parsed_args.book) == false -> {:error, 'Path #{parsed_args.book} is an invalid path'}
      parsed_args.port < 1024 -> {:error, 'Invalid port number #{parsed_args.port}'}
      true -> {:ok, parsed_args}
    end
  end

  @doc """
  Display the error, and provide the help.
  """
  def display_error(err_msg) do
    IO.puts("Error: #{err_msg}")
    IO.puts("#{@script_name} --book <path> --port <port number>")
    defaults = default_args()
    #IO.inspect(defaults)
    IO.puts("\t\t --book #{defaults.book} --port #{defaults.port}")
  end
end

defmodule LivebookInit do
  @moduledoc """
  Start the livebook based on the arguments.
  """

  # The docker command.
  defp docker_cmd() do
    %{cmd: "/usr/bin/docker", container_name: "livebook", image_name: "ghcr.io/livebook-dev/livebook"}
  end

  @doc """
  stop the previous instance, and start a new instance.
  This is basically a restart. Note that only one instance of livebook will be running at any given point of time.
  TODO: add a cleanup when CTRL-C is provided.
  """
  def start(args) do
    if args.stop == false do
      IO.puts("Starting livebook with Books at #{args.book} and Port number #{args.port}")
      cleanup(docker_cmd())
      initialize(docker_cmd(), args)
    else
      IO.puts("Stopping livebook")
      cleanup(docker_cmd())
    end
  end

  #Stop any previous instance, and remove the container process.
  defp cleanup(docker) do
    IO.puts("Force stopping any livebook containers that may be running.")
    System.cmd(docker.cmd, ["stop", docker.container_name])
    System.cmd(docker.cmd, ["rm", docker.container_name])
    IO.puts("Ignoring above errors")
  end

  #Start a new instance with the arguments.
  defp initialize(docker, args) do
    {ret, uid, gid} = get_uidgid()
    cmd_args = ["run", "--rm", "--name", docker.container_name, "-e", "LIVEBOOK_TOKEN_ENABLED=false",
          "-p", "#{args.port}:#{args.port}", "-u", "#{uid}:#{gid}",
          "-v", "#{args.book}:/data", docker.image_name
        ]
    #IO.inspect(cmd_args)
    #cmd_string = "#{docker.cmd} run --rm --name #{docker.container_name} -e LIVEBOOK_TOKEN_ENABLED=false -p #{args.port}:#{args.port} -u #{uid}:#{gid} -v #{args.book}:/data #{docker.image_name}"
    case ret do
      :ok -> System.cmd(docker.cmd, cmd_args, into: IO.stream(:stdio, :line))
       _ -> IO.puts("Error in fetching the UID and GID")
    end
  end

  # Get the uid and gid to ensure that the files are accessible and can be written from within docker.
  defp get_uidgid() do
    case {System.cmd("id", ["-u"]), System.cmd("id", ["-g"])} do
      {{uid_str, 0}, {gid_str, 0}} -> {:ok, String.trim(uid_str) |> String.to_integer, String.trim(gid_str) |> String.to_integer}
      _ -> {:error, 0, 0}
    end
  end
end

# Only one instance of livebook will be running on the system when using this command.
case CommandLineParser.parse(System.argv()) do
  {:ok, parsed_args} -> LivebookInit.start(parsed_args)
  {:error, err_msg} -> CommandLineParser.display_error(err_msg)
  _ -> IO.puts("Error")
end
