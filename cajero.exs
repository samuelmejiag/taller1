defmodule CajeroAutomatico do

  @moduledoc """
  Módulo encargado de la simulación de retiros de dinero en un cajero automático.


  """



# Atributos de módulo como constantes
  @pin_correcto "0482"
  @saldo_disponible 450_000.0
  @limite_por_retiro 600_000.0

  @comision_corriente 4_000.0
  @comision_ahorros_alta 2_500.0
  @comision_ahorros_baja 0.0

  @tope_ahorros_sin_comision 200_000.0


  @doc """
  Punto de entrada interactivo en terminal para el uso del cajero.

  Solicita los datos del usuario utilizando las funciones auxiliares de `Util` y
  muestra el comprobante final.
  """

  def main do

    pin = Util.leer("Ingrese su PIN: ", :string)
    cuenta = Util.leer("Tipo de cuenta (ahorros/corriente): ", :string)
    monto = Util.leer("Monto a retirar: ", :float)

    resultado = realizar_retiro(pin, cuenta, monto)
    mostrar_comprobante(resultado)
  end


  @doc """
  Ejecuta secuencialmente las validaciones requeridas para procesar un retiro.

  Utiliza la estructura `with` para detener el flujo en la primera validación que falle.

  """

  def realizar_retiro(pin, cuenta, monto) do
    with {:ok, _} <- validar_pin(pin),
         {:ok, cuenta_atom} <- validar_tipo_cuenta(cuenta),
         {:ok, _} <- validar_monto_positivo(monto),
         {:ok, _} <- validar_multiplo_diez_mil(monto),
         {:ok, _} <- validar_limite_retiro(monto),
         comision = calcular_comision(cuenta_atom, monto),
         {:ok, saldo_restante} <- validar_saldo_suficiente(monto, comision) do
      billetes = calcular_billetes(trunc(monto))
      {:ok, {monto, comision, saldo_restante, billetes}}
    else
      {:error, motivo} -> {:error, motivo}
    end
  end

  # Validaciones con guards y pattern matching (Guía 6)
  defp validar_pin(@pin_correcto), do: {:ok, true}
  defp validar_pin(_), do: {:error, "PIN incorrecto"}

  defp validar_tipo_cuenta(str) do
    case String.downcase(str) do
      "ahorros" -> {:ok, :ahorros}
      "corriente" -> {:ok, :corriente}
      _ -> {:error, "Tipo de cuenta no válido"}
    end
  end

  defp validar_monto_positivo(monto) when monto > 0, do: {:ok, true}
  defp validar_monto_positivo(_), do: {:error, "El monto debe ser mayor que cero"}

  defp validar_multiplo_diez_mil(monto) when rem(trunc(monto), 10_000) == 0, do: {:ok, true}
  defp validar_multiplo_diez_mil(_), do: {:error, "El monto debe ser múltiplo de $10.000"}

  defp validar_limite_retiro(monto) when monto <= @limite_por_retiro, do: {:ok, true}
  defp validar_limite_retiro(_), do: {:error, "El monto supera el límite por retiro"}

  defp validar_saldo_suficiente(monto, comision) when monto + comision <= @saldo_disponible do
    {:ok, @saldo_disponible - (monto + comision)}
  end

  defp validar_saldo_suficiente(_, _),
    do: {:error, "Fondos insuficientes para cubrir el monto y la comisión"}

  # Pattern matching y Guards para la comisión
  defp calcular_comision(:corriente, _monto), do: @comision_corriente

  defp calcular_comision(:ahorros, monto) when monto <= @tope_ahorros_sin_comision,
    do: @comision_ahorros_baja

  defp calcular_comision(:ahorros, monto) when monto > @tope_ahorros_sin_comision,
    do: @comision_ahorros_alta

  # Desglose de billetes
  defp calcular_billetes(monto) do
    b50 = div(monto, 50_000)
    resto_50 = rem(monto, 50_000)
    b20 = div(resto_50, 20_000)
    resto_20 = rem(resto_50, 20_000)
    b10 = div(resto_20, 10_000)
    {b50, b20, b10}
  end

  @doc """
  Imprime en la pantalla el comprobante sencillo de la transacción o la razón del rechazo.


  """
  def mostrar_comprobante({:ok, {monto, comision, saldo_restante, {b50, b20, b10}}}) do
    Util.imprimir_mensaje("""
    Monto retirado: $#{formatear_moneda(monto)}
    Comisión: $#{formatear_moneda(comision)}
    Total debitado: $#{formatear_moneda(monto + comision)}
    Saldo restante: $#{formatear_moneda(saldo_restante)}
    Billetes de 50.000: #{b50}
    Billetes de 20.000: #{b20}
    Billetes de 10.000: #{b10}
    """)
  end

  def mostrar_comprobante({:error, motivo}) do
    Util.imprimir_mensaje("Error: #{motivo}")
  end

  defp formatear_moneda(valor) do
    :erlang.float_to_binary(valor, [{:decimals, 2}, :compact])
  end
end

CajeroAutomatico.main()
