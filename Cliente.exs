# Archivo: cliente.exs

defmodule Cliente do
  @doc """
  Función helper para encapsular la lógica de enviar una petición
  y esperar (receive) una respuesta del servidor.
  """
  defp rpc(server_pid_tuple, message) do
    # Enviamos la petición al tupla {NombreRegistrado, Nodo} [cite: 29]
    send(server_pid_tuple, {self(), message})

    # Esperamos la respuesta
    receive do
      response -> response
    after
      5000 -> {:error, :timeout} # Timeout de 5 segundos
    end
  end

  @doc """
  Punto de entrada del cliente.
  Se conecta al nodo servidor y ejecuta el flujo de consulta.
  """
  def start(server_node_name) do
    # 1. Conectar al nodo del servidor [cite: 28]
    case Node.connect(server_node_name) do
      true ->
        IO.puts("🔌 Conectado exitosamente al nodo servidor: #{server_node_name}")
        # La tupla para contactar al proceso registrado en el otro nodo
        server_pid_tuple = {:servidor_procesos, server_node_name}

        # 2. Solicitar lista de trabajos al iniciar [cite: 24]
        IO.puts("\n--- 📚 Obteniendo lista de trabajos de grado... ---")
        case rpc(server_pid_tuple, :get_all_projects) do
          {:projects_list, projects} ->
            IO.inspect(projects, label: "Trabajos Disponibles", limit: :infinity)
            handle_user_selection(server_pid_tuple, projects)

          {:error, :timeout} ->
            IO.puts("Error: Timeout esperando la lista de proyectos.")
        end

      false ->
        IO.puts("Error: No se pudo conectar al nodo #{server_node_name}.")
        IO.puts("Asegúrese que el nodo servidor esté corriendo y la cookie sea la misma.")
    end
  end

  @doc """
  Maneja la lógica de selección del usuario [cite: 26]
  """
  defp handle_user_selection(server_pid_tuple, projects) do
    if Enum.empty?(projects) do
      IO.puts("No hay trabajos para seleccionar.")
    else
      # 3. Permitir al usuario seleccionar un trabajo
      IO.puts("\n--- 🔎 Consulta de Autores ---")
      IO.puts("Escriba el Título exacto de un trabajo de la lista para ver sus autores:")
      # Leer la entrada del usuario
      selected_title = IO.gets("> ") |> String.trim()

      # 4. Consultar al servidor por los autores [cite: 26]
      IO.puts("\n--- Consultando autores para '#{selected_title}'... ---")
      case rpc(server_pid_tuple, {:get_authors, selected_title}) do
        {:author_details, authors} ->
          IO.inspect(authors, label: "Autores Encontrados", limit: :infinity)

        {:error, "Trabajo no encontrado"} ->
          IO.puts("Error: El trabajo '#{selected_title}' no fue encontrado en el servidor.")

        {:error, :timeout} ->
          IO.puts("Error: Timeout esperando respuesta de autores.")
      end
    end
  end
end
