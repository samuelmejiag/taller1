defmodule Biblioteca do

  @moduledoc """
  Calcula la multa por devolución tardía de un libro.
  """

  @valor_dia 500
  @tope_multa 20000
  @descuento_estudiante 50

  def main do

    codigo = Util.leer("Ingrese el código del libro: ", :string)
    dias = Util.leer("Ingrese los días de retraso: ", :integer)
    tipo = Util.leer("Tipo de usuario (estudiante/docente): ", :string)

    procesar(codigo, dias, tipo)
    |> generar_mensaje()
    |> Util.imprimir_mensaje()

  end

  defp procesar(codigo, dias, tipo) do

    with {:ok, codigo} <- validar_codigo(codigo),
         {:ok, dias} <- validar_dias(dias),
         {:ok, tipo} <- convertir_tipo(tipo) do

      multa =
        calcular_multa(dias)
        |> aplicar_descuento(tipo)

      {:ok, codigo, multa}

    end

  end

  defp validar_codigo(codigo) do
  if String.length(codigo) == 6 do
    {:ok, codigo}
  else
    {:error, "El código debe tener 6 caracteres"}
  end
end

  defp validar_dias(dias) when is_integer(dias) and dias >= 0, do: {:ok, dias}
  defp validar_dias(_), do: {:error, "Los días de retraso no pueden ser negativos"}

  defp convertir_tipo("estudiante"), do: {:ok, :estudiante}
  defp convertir_tipo("docente"), do: {:ok, :docente}
  defp convertir_tipo(_), do: {:error, "Tipo de usuario no válido"}

  defp calcular_multa(dias) when dias > 40, do: @tope_multa
  defp calcular_multa(dias) when dias > 0, do: dias * @valor_dia
  defp calcular_multa(_), do: 0

  defp aplicar_descuento(multa, :estudiante), do: div(multa * @descuento_estudiante, 100)
  defp aplicar_descuento(multa, :docente), do: multa

  defp generar_mensaje({:ok, codigo, 0}), do: "El libro #{codigo} no tiene multa"
  defp generar_mensaje({:ok, codigo, multa}), do: "El libro #{codigo} tiene una multa de $#{multa}"
  defp generar_mensaje({:error, motivo}), do: "Error: #{motivo}"

end

Biblioteca.main()
