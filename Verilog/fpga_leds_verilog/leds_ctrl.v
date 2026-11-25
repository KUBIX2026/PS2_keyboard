//============================================================================
// leds_ctrl : logica de salida de LEDs (bloque secuencial)
//
// Recibe de "Identificar trama" un pulso 'key_stroke' (1 ciclo) junto con el
// 'indice' (0..7) de la tecla de control que se acaba de PRESIONAR (make).
// El 'indice' viene de ID_trama:
//    0=A  1=B  2=Select  3=Start  4=Up  5=Down  6=Left  7=Right
//
// Comportamiento:
//   - "Barra" de fondo acumulativa: cada pulsacion sube un nivel (1 LED mas),
//     de 1 en 1 hasta llenar los N_LEDS; al llenarse avanza "de a 2" con wrap.
//   - DESTELLO (flash) visible y corto en cada pulsacion: durante el flash se
//     muestran SOLO los LEDs de la tecla pulsada y el resto se apaga. Asi la
//     pulsacion SIEMPRE se percibe, incluso si cae sobre un LED que ya estaba
//     encendido por la barra (lo demas se apaga un instante por contraste).
//   - El destello dura FLASH_CYCLES ciclos de 'clk' (~visible pero corto).
//
// Mapeo indice -> LED (destello):
//     Left  (6)->LED1  Right (7)->LED2  Up   (4)->LED3
//     Down  (5)->LED4  Start (3)->LED5  Select(2)->LED6
//     A (0) y B (1) no tienen LED propio (solo hay 6 LEDs): destellan DOS LEDs
//       A -> los dos de la IZQUIERDA (LED1+LED2)
//       B -> los dos de la DERECHA  (LED5+LED6)
//
// La placa tiene 6 LEDs ACTIVOS EN BAJO. Este modulo entrega 'leds' en
// logica positiva (1 = encendido); el top los invierte para la placa.
//============================================================================
module leds_ctrl #(
  parameter N_LEDS      = 6,
  // Duracion del destello en ciclos de clk. A 27 MHz, 4_000_000 ~= 148 ms.
  parameter FLASH_CYCLES = 27'd4_000_000
)(
  input                   clk,
  input                   rst,          // reset sincrono, activo en alto
  input                   key_stroke,   // pulso de 1 ciclo: tecla make valida
  input      [2:0]        indice,       // indice de la tecla (0..7)

  output reg [N_LEDS-1:0] leds          // 1 = LED encendido (logica positiva)
);

  // Mapa indice de tecla -> mascara de LEDs que destellan.
  // 6 teclas tienen LED propio; las 2 que "sobran" (A y B) destellan DOS LEDs:
  //   A -> los dos LEDs de MAS A LA IZQUIERDA (LED1+LED2)
  //   B -> los dos LEDs de MAS A LA DERECHA  (LED5+LED6)
  // Orientacion: LED1 = extremo izquierdo (bit 0), LED6 = extremo derecho (bit 5).
  reg [N_LEDS-1:0] led_tecla;
  always @(*) begin
    case (indice)
      3'd6:    led_tecla = 6'b000001;  // Left   -> LED1
      3'd7:    led_tecla = 6'b000010;  // Right  -> LED2
      3'd4:    led_tecla = 6'b000100;  // Up     -> LED3
      3'd5:    led_tecla = 6'b001000;  // Down   -> LED4
      3'd3:    led_tecla = 6'b010000;  // Start  -> LED5
      3'd2:    led_tecla = 6'b100000;  // Select -> LED6
      3'd0:    led_tecla = 6'b000011;  // A -> dos LEDs de la IZQUIERDA (LED1+LED2)
      3'd1:    led_tecla = 6'b110000;  // B -> dos LEDs de la DERECHA  (LED5+LED6)
      default: led_tecla = 6'b000000;
    endcase
  end

  // --- Barra de fondo acumulativa ---
  reg [3:0]        nivel;   // cuantos LEDs enciende la barra (0..N_LEDS)
  reg [N_LEDS-1:0] barra;   // los 'nivel' LEDs menos significativos encendidos

  integer k;
  always @(*) begin
    for (k = 0; k < N_LEDS; k = k + 1)
      barra[k] = (k < nivel);
  end

  // --- Destello temporal ---
  reg [26:0]       flash_cnt;    // ciclos restantes del destello (0 = inactivo)
  reg [N_LEDS-1:0] flash_mask;   // que LED esta destellando (one-hot)
  wire             flashing = (flash_cnt != 27'd0);

  always @(posedge clk) begin
    if (rst) begin
      nivel      <= 4'd0;
      flash_cnt  <= 27'd0;
      flash_mask <= {N_LEDS{1'b0}};
    end else begin
      // Nueva pulsacion: sube la barra y lanza el destello del LED de la tecla.
      if (key_stroke) begin
        if (nivel < N_LEDS)
          nivel <= nivel + 4'd1;                               // de 1 en 1
        else
          nivel <= (nivel + 4'd2 > N_LEDS) ? 4'd2 : nivel + 4'd2; // de a 2 (wrap)

        flash_mask <= led_tecla;        // LED que va a destellar
        flash_cnt  <= FLASH_CYCLES;     // (re)arranca el temporizador
      end else if (flashing) begin
        flash_cnt <= flash_cnt - 27'd1; // consume el tiempo del destello
      end
    end
  end

  // Salida visible:
  //   - Durante el DESTELLO: se muestran SOLO los LEDs de la tecla pulsada
  //     (1 LED para teclas normales; 2 LEDs para A/B). El resto se apaga, de
  //     modo que la pulsacion SIEMPRE se percibe, incluso si cae sobre un LED
  //     que ya estaba encendido en la barra (todo lo demas se apaga un instante).
  //   - En REPOSO: se muestra la barra acumulativa de fondo.
  always @(*) begin
    if (flashing)
      leds = flash_mask;
    else
      leds = barra;
  end

endmodule
