# PS/2 → LEDs en Tang Nano 9K

Programa para la FPGA que integra **Recepción PS/2** + **Identificar trama** y
enciende los LEDs de la placa según la tecla de control presionada.

## Cadena de módulos

```
Teclado PS/2 ─► RX_PS2 ─► ID_trama ─► leds_ctrl ─► 6 LEDs (Tang Nano 9K)
             (recepción) (identificar)  (salida)
```

- **RX_PS2** (de `../Recepcion_verilog/`): recibe cada byte PS/2.
- **ID_trama** (de `../IdentificarTrama_verilog/`): identifica el scancode y
  entrega un `indice` (0..7) para las teclas de control, más `idx_valid` e `is_f0`.
- **leds_ctrl** (`leds_ctrl.v`): lógica de salida de LEDs.
- **top_ps2_leds** (`top_ps2_leds.v`): TOP de la placa. Sincroniza y filtra las
  líneas PS/2, maneja el break code (`0xF0`) para contar solo pulsaciones.

## Comportamiento de los LEDs

Cada **pulsación (make)** de una tecla de control produce un **destello corto y
visible** (~148 ms) del/los LED(s) de esa tecla. Durante el destello se muestran
**solo** esos LEDs y el resto se apaga, así la pulsación **siempre se nota**,
incluso si cae sobre un LED que ya estaba encendido.

En reposo se ve una **barra acumulativa**: cada pulsación sube un nivel (1 LED
más), de 1 en 1 hasta llenar los 6 LEDs; al llenarse, avanza **de a 2** (con wrap).

Las **sueltas (break, `0xF0 + scancode`) se ignoran**: no cuentan ni destellan.

### Mapeo tecla → LED

Orientación: **LED1 = extremo izquierdo**, **LED6 = extremo derecho**.

| Tecla  | índice | scancode make | LED(s) que destellan |
|--------|:------:|:-------------:|----------------------|
| Left   | 6      | `1C`          | LED1                 |
| Right  | 7      | `23`          | LED2                 |
| Up     | 4      | `1D`          | LED3                 |
| Down   | 5      | `1B`          | LED4                 |
| Start  | 3      | `5A`          | LED5                 |
| Select | 2      | `29`          | LED6                 |
| **A**  | 0      | `3B`          | **LED1+LED2** (dos de la izquierda) |
| **B**  | 1      | `42`          | **LED5+LED6** (dos de la derecha)   |

Como solo hay 6 LEDs para 8 teclas, las dos teclas que "sobran" (A y B) se
distinguen encendiendo **dos LEDs**: A los dos de la izquierda, B los dos de la
derecha.

## Simulación

```bash
source digital-logic-design activate
make sim      # compila con iverilog y corre el testbench
make wave     # abre las ondas en gtkwave
```

El testbench (`top_ps2_leds_TB.v`) inyecta scancodes PS/2 reales (con paridad
impar y flancos de reloj) y reporta el estado de los LEDs en cada tecla,
incluyendo el caso de LED repetido y el break code.

## Síntesis y carga a la FPGA

Flujo con la OSS CAD Suite (yosys + nextpnr-himbaechel + gowin_pack):

```bash
source digital-logic-design activate
make synth    # genera top_ps2_leds.fs (bitstream)
make load     # carga a la SRAM (volátil) con openFPGALoader
make flash    # graba en la flash (persistente)
```

## Conexión del teclado PS/2

El teclado PS/2 usa líneas **open-drain con pull-up a 3.3 V**. Conecta:

- `PS2_CLK`  → pin del header definido en `tangnano9k.cst` (`ps2_clk`, pin 25).
- `PS2_DATA` → pin del header definido en `tangnano9k.cst` (`ps2_dat`, pin 26).
- `GND` y `+5V`/`+3.3V` del teclado según corresponda.

> Ajusta los pines en `tangnano9k.cst` a tu cableado real. Los pines de LEDs,
> reloj (27 MHz, pin 52) y reset (pin 4) son los estándar del Tang Nano 9K.
