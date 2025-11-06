# Archivo: servidor.exs

defmodule Servidor do
  @doc """
  Datos de los autores
  """
  @autores %{
    "101" => %{nombre: "Ana", apellidos: "Garcia", cedula: "101", programa: "ISC", titulo: "Ingeniera"},
    "102" => %{nombre: "Luis", apellidos: "Perez", cedula: "102", programa: "ISC", titulo: "Ingeniero"},
    "103" => %{nombre: "Maria", apellidos: "Rojas", cedula: "103", programa: "Civil", titulo: "Ingeniera"},
    "104" => %{nombre: "Juan", apellidos: "Castro", cedula: "104", programa: "ISC", titulo: "Ingeniero"},
    "105" => %{nombre: "Sofia", apellidos: "Marin", cedula: "105", programa: "Electronica", titulo: "Ingeniera"}
  }

  @doc """
  Datos de los trabajos de grado
  Cada uno tiene al menos 2 autores
  """
  @trabajos %{
    "Sistema de Riego" => %{fecha: "2024-01-10", descripcion: "Riego automatico", autores: ["101", "102"]},
    "App Movil de Notas" => %{fecha: "2024-03-15", descripcion: "App Android para notas", autores: ["103", "104"]},
    "Analisis de Redes" => %{fecha: "2024-05-20", descripcion: "Seguridad en redes locales", autores: ["101", "105"]}
  }

  @doc """
  Inicia el servidor.
  Crea un nuevo proceso y lo registra globalmente como :servidor_procesos
  """
  def start do
    # Usamos spawn como se requiere [cite: 29]
    Process.register(spawn(fn -> loop() end), :servidor_procesos)
    IO.puts("✅ Servidor de Trabajos de Grado iniciado.")
    IO.puts("   Registrado como :servidor_procesos en este nodo.")
  end

  @doc """
  El ciclo principal del servidor que espera mensajes (peticiones).
  Esto implementa la parte 'receive' de la comunicación. [cite: 29]
  """
  def loop do
    receive do
      # Petición 1: Obtener todos los trabajos [cite: 18]
      {sender_pid, :get_all_projects} ->
        # Preparamos la lista de trabajos para enviar
        projects_list =
          Enum.map(@trabajos, fn {titulo, data} ->
            %{titulo: titulo, fecha: data.fecha, descripcion: data.descripcion}
          end)

        # Enviamos la respuesta al cliente
        send(sender_pid, {:projects_list, projects_list})
        loop()

      # Petición 2: Obtener autores de un trabajo específico [cite: 19]
      {sender_pid, {:get_authors, titulo}} ->
        case Map.get(@trabajos, titulo) do
          nil ->
            # Caso de error: trabajo no encontrado
            send(sender_pid, {:error, "Trabajo no encontrado"})

          project_data ->
            # 1. Obtenemos las cédulas de los autores [cite: 13]
            author_ids = project_data.autores

            # 2. Buscamos los datos completos de cada autor [cite: 14, 15]
            full_authors = Enum.map(author_ids, fn id -> Map.get(@autores, id) end)

            # 3. Enviamos la respuesta
            send(sender_pid, {:author_details, full_authors})
        end

        loop()

      # Ignorar otros mensajes
      _ ->
        loop()
    end
  end
end
