defmodule Cupon do
  @moduledoc """
  Este módulo se encarga de recibir, validar y dar una respuesta sobre un código
  de cupón promocional, verificando que cumpla con reglas específicas de seguridad
  (longitud, mayúsculas, números y espacios).
  """

  @longitud_minima 10
  @numeros ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

  @doc """
  Función principal (punto de entrada).
  Pide al usuario que ingrese un código, lo envía al validador y luego imprime
  en pantalla si el cupón es válido o la lista de errores que tuvo.
  """
  def main do
    "Ingrese el codigo del cupon:"
    |> Util.leer(:string)
    |> validar_cupon()
    |> generar_mensaje()
    |> Util.imprimir_mensaje()
  end

  @doc """
  Recibe un texto (el cupón) y lo pasa por un túnel (pipe) de 4 revisiones.
  Va acumulando los errores encontrados sin detener el proceso y al final
  construye el resultado usando una tupla `{:ok, ...}` o `{:error, ...}`.
  """
  def validar_cupon(cupon) do
    {cupon, ""}
    |> validar_longitud()
    |> validar_mayuscula()
    |> validar_numero()
    |> validar_espacios()
    |> construir_resultado()
  end

  # Verifica que el cupón tenga al menos 10 letras/caracteres.
  defp validar_longitud({cupon, errores}) do
    if String.length(cupon) < @longitud_minima do
      {cupon, agregar_error(errores, "debe tener al menos 10 caracteres")}
    else
      {cupon, errores}
    end
  end

  # Revisa si hay al menos una mayúscula. Lo hace convirtiendo todo a minúsculas
  # y comparándolo con el original. Si son iguales, es que no había mayúsculas.
  defp validar_mayuscula({cupon, errores}) do
    if cupon == String.downcase(cupon) do
      {cupon, agregar_error(errores, "debe contener al menos una letra mayúscula")}
    else
      {cupon, errores}
    end
  end

  # Borra todos los números del cupón. Si el tamaño de la palabra sigue siendo
  # el mismo después de borrarlos, significa que no tenía ningún número.
  defp validar_numero({cupon, errores}) do
    cupon_sin_numeros = String.replace(cupon, @numeros, "")

    if String.length(cupon) == String.length(cupon_sin_numeros) do
      {cupon, agregar_error(errores, "debe contener al menos un número")}
    else
      {cupon, errores}
    end
  end

  # Revisa de forma directa si el cupón contiene un espacio en blanco.
  defp validar_espacios({cupon, errores}) do
    if String.contains?(cupon, " ") do
      {cupon, agregar_error(errores, "no debe contener espacios")}
    else
      {cupon, errores}
    end
  end

  # Pega el nuevo error al texto de errores. Si es el primer error, no le pone coma.
  defp agregar_error("", nuevo_error), do: nuevo_error
  defp agregar_error(errores, nuevo_error), do: errores <> ", " <> nuevo_error

  # Si el texto de errores llega vacío, retorna éxito. Si tiene texto, retorna error.
  defp construir_resultado({_cupon, ""}), do: {:ok, "Cupón válido"}
  defp construir_resultado({_cupon, errores}), do: {:error, errores}

  # Le da un formato bonito al texto final antes de imprimirlo en pantalla.
  defp generar_mensaje({:ok, mensaje}), do: "Éxito: #{mensaje}"
  defp generar_mensaje({:error, errores}), do: "Error: #{errores}"
end

Cupon.main()
