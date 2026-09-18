defmodule PaqueteTuristico do
  @moduledoc """
  Módulo para la cotización de paquetes turísticos usando la tubería |> para simplificar el flujo.
  """

  # Atributos de módulo como constantes (Guías 5 y 6)
  @dest_bogota 1
  @dest_medellin 2
  @dest_cartagena 3
  @dest_san_andres 4

  @tarifa_bogota 180_000.0
  @tarifa_medellin 150_000.0
  @tarifa_cartagena 220_000.0
  @tarifa_san_andres 280_000.0

  @costo_maleta 45_000.0
  @costo_seguro_noche 12_000.0

  @desc_frecuente 0.20
  @desc_corporativo 0.15
  @desc_ocasional 0.00

  @recargo_alta 0.25
  @recargo_media 0.10
  @recargo_baja 0.00

  @desc_paquete 0.05
  @noches_min_desc_paquete 3

  @doc """
  Punto de entrada principal. Captura las entradas, las canaliza por la tubería |>
  hacia el cálculo y envía el resultado a la función de impresión.
  """
  def main do
    destino =
      Util.leer(
        "Ingrese el código del destino (1: Bogotá, 2: Medellín, 3: Cartagena, 4: San Andrés): ",
        :integer
      )

    noches = Util.leer("Ingrese el número de noches (1 a 30): ", :integer)

    cliente =
      Util.leer("Ingrese el tipo de cliente (frecuente, corporativo u ocasional): ", :string)

    mes = Util.leer("Ingrese el mes del viaje (1 a 12): ", :integer)
    maleta = Util.leer("¿Desea llevar maleta de bodega adicional? (si/no): ", :string)
    seguro = Util.leer("¿Desea incluir seguro de viaje por noche? (si/no): ", :string)

    # Uso del operador pipe para encadenar el cálculo y la impresión (Guía 4)
    calcular_paquete(destino, noches, cliente, mes, maleta, seguro)
    |> mostrar_resultado()
  end

  @doc """
  Valida los parámetros con `with` y desencadena la lógica de cálculo.
  """
  def calcular_paquete(destino, noches, cliente, mes, maleta, seguro) do
    with {:ok, dest_val} <- validar_destino(destino),
         {:ok, noches_val} <- validar_noches(noches),
         {:ok, mes_val} <- validar_mes(mes),
         {:ok, cliente_atom} <- validar_cliente(cliente),
         {:ok, maleta_bool} <- validar_booleano(maleta),
         {:ok, seguro_bool} <- validar_booleano(seguro) do
      procesar_calculos(dest_val, noches_val, cliente_atom, mes_val, maleta_bool, seguro_bool)
    end
  end

  # Validaciones con Guards (Guía 6)
  defp validar_destino(d) when d in 1..4, do: {:ok, d}
  defp validar_destino(_), do: {:error, "Destino inválido (debe ingresar un número entre 1 y 4)"}

  defp validar_noches(n) when n in 1..30, do: {:ok, n}
  defp validar_noches(_), do: {:error, "Número de noches inválido (debe ser de 1 a 30)"}

  defp validar_mes(m) when m in 1..12, do: {:ok, m}
  defp validar_mes(_), do: {:error, "Mes inválido (debe ser un número del 1 al 12)"}

  # Normalización con pipe de cadenas (Guía 4)
  defp validar_cliente(str) do
    case str |> String.downcase() do
      "frecuente" -> {:ok, :frecuente}
      "corporativo" -> {:ok, :corporativo}
      "ocasional" -> {:ok, :ocasional}
      _ -> {:error, "Tipo de cliente no válido (escriba: frecuente, corporativo u ocasional)"}
    end
  end

  defp validar_booleano(str) do
    case str |> String.downcase() do
      "si" -> {:ok, true}
      "no" -> {:ok, false}
      _ -> {:error, "Respuesta no válida (responda 'si' o 'no')"}
    end
  end

  # Lógica de cálculo pura
  defp procesar_calculos(destino, noches, cliente, mes, maleta_req, seguro_req) do
    tarifa_vuelo = tarifa_base_vuelo(destino)
    {valor_maleta, origen_maleta} = calcular_maleta(destino, maleta_req)

    tarifa_noche = obtener_tarifa_noche(noches)
    subtotal_hotel = tarifa_noche * noches
    pct_desc_cliente = obtener_descuento_cliente(cliente)
    monto_descuento = subtotal_hotel * pct_desc_cliente
    alojamiento_con_desc = subtotal_hotel - monto_descuento

    pct_recargo = obtener_recargo_mes(mes)
    monto_recargo = alojamiento_con_desc * pct_recargo
    alojamiento_final = alojamiento_con_desc + monto_recargo

    monto_seguro = if seguro_req, do: @costo_seguro_noche * noches, else: 0.0
    base_paquete = alojamiento_final + monto_seguro

    monto_desc_paquete =
      if noches >= @noches_min_desc_paquete do
        base_paquete * @desc_paquete
      else
        0.0
      end

    total = tarifa_vuelo + valor_maleta + base_paquete - monto_desc_paquete

    {:ok,
     {
       {tarifa_vuelo, valor_maleta, origen_maleta},
       {tarifa_noche, subtotal_hotel, monto_descuento, monto_recargo},
       {monto_seguro, monto_desc_paquete, total}
     }}
  end

  # Pattern matching con atributos de módulo
  defp tarifa_base_vuelo(@dest_bogota), do: @tarifa_bogota
  defp tarifa_base_vuelo(@dest_medellin), do: @tarifa_medellin
  defp tarifa_base_vuelo(@dest_cartagena), do: @tarifa_cartagena
  defp tarifa_base_vuelo(@dest_san_andres), do: @tarifa_san_andres

  # Guard para maleta obligatoria
  defp es_maleta_obligatoria?(destino) when destino in [@dest_san_andres], do: true
  defp es_maleta_obligatoria?(_), do: false

  defp calcular_maleta(destino, solicitada) do
    obligatoria = es_maleta_obligatoria?(destino)

    cond do
      obligatoria and solicitada -> {@costo_maleta, :solicitado}
      obligatoria and not solicitada -> {@costo_maleta, :automatico}
      not obligatoria and solicitada -> {@costo_maleta, :solicitado}
      true -> {0.0, :no_aplica}
    end
  end

  # Guards para tarifa por noche según noches
  defp obtener_tarifa_noche(n) when n in 1..2, do: 120_000.0
  defp obtener_tarifa_noche(n) when n in 3..5, do: 100_000.0
  defp obtener_tarifa_noche(n) when n in 6..30, do: 85_000.0

  # Pattern matching sobre átomos para descuento de cliente
  defp obtener_descuento_cliente(:frecuente), do: @desc_frecuente
  defp obtener_descuento_cliente(:corporativo), do: @desc_corporativo
  defp obtener_descuento_cliente(:ocasional), do: @desc_ocasional

  # Cond para recargo de temporada según el mes
  defp obtener_recargo_mes(mes) do
    cond do
      mes in [12, 1] -> @recargo_alta
      mes in [6, 7] -> @recargo_media
      true -> @recargo_baja
    end
  end

  # Impresión usando el módulo Util
  def mostrar_resultado(
        {:ok,
         {
           {tarifa_vuelo, valor_maleta, origen_maleta},
           {tarifa_noche, subtotal_hotel, descuento, recargo},
           {seguro, descuento_paquete, total}
         }}
      ) do
    str_origen =
      case origen_maleta do
        :automatico -> " (Agregada automáticamente por política de destino)"
        :solicitado -> " (Solicitada por el usuario)"
        :no_aplica -> " (No incluida)"
      end

    """

    Vuelo y maleta:
      - Tarifa Base Vuelo: $#{formatear_moneda(tarifa_vuelo)}
      - Maleta de Bodega:  $#{formatear_moneda(valor_maleta)}#{str_origen}

    Alojamiento:
      - Tarifa/Noche:      $#{formatear_moneda(tarifa_noche)}
      - Subtotal Hotel:    $#{formatear_moneda(subtotal_hotel)}
      - Descuento Cliente: -$#{formatear_moneda(descuento)}
      - Recargo Temporada: +$#{formatear_moneda(recargo)}

    Servicios adicionales:
      - Seguro de Viaje:   $#{formatear_moneda(seguro)}
      - Descuento Paquete (5%): -$#{formatear_moneda(descuento_paquete)}

    Valor total:   $#{formatear_moneda(total)}
    """
    |> Util.imprimir_mensaje()
  end

  def mostrar_resultado({:error, motivo}) do
    "Error al calcular el paquete: #{motivo}"
    |> Util.imprimir_mensaje()
  end

  defp formatear_moneda(valor) do
    valor
    |> :erlang.float_to_binary([{:decimals, 2}, :compact])
  end
end
