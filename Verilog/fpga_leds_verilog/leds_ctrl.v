//============================================================================
// leds_ctrl : logica de salida de LEDs (bloque secuencial)
//
// Recibe de "Identificar trama" un pulso 'key_stroke' (1 ciclo) junto con el
// 'indice' (0..7) de la tecla de control que se acaba de PRESIONAR (make).
// El 'indice' viene de ID_trama:
//    0=A  1=B  2=Select  3=Start  4=Up  5=Down  6=Left  7=Right
//
// Comportamiento (SIN barra de fondo, solo DESTELLO por pulsacion):
//   - En reposo TODOS los LEDs estan apagados.
//   - Cada pulsacion valida (key_stroke) enciende SOLO el/los LED(s) de esa
//     tecla durante FLASH_CYCLES ciclos (~0.3 s) y luego se apaga.
//   - Si se MANTIENE la tecla, el teclado reenvia tramas (typematic/repeat);
//     cada trama vuelve a lanzar key_stroke y RE-ARRANCA el temporizador, de
//     modo que el LED permanece encendido mientras se mantiene pulsada y se
//     apaga ~0.3 s despues de soltar.
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
  // Duracion del destello en ciclos de clk. A 27 MHz, 8_100_000 ~= 0.3 s.
  parameter FLASH_CYCLES = 27'd8_100_000
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

  // --- Destello temporal ---
  reg [26:0]       flash_cnt;    // ciclos restantes del destello (0 = inactivo)
  reg [N_LEDS-1:0] flash_mask;   // que LED(s) estan destellando
  wire             flashing = (flash_cnt != 27'd0);

  always @(posedge clk) begin
    if (rst) begin
      flash_cnt  <= 27'd0;
      flash_mask <= {N_LEDS{1'b0}};
    end else begin
      // Nueva pulsacion (incluye las repeticiones typematic al mantener):
      // fija el/los LED(s) de la tecla y (re)arranca el temporizador.
      if (key_stroke) begin
        flash_mask <= led_tecla;        // LED(s) que van a encenderse
        flash_cnt  <= FLASH_CYCLES;     // (re)arranca el temporizador (~0.3 s)
      end else if (flashing) begin
        flash_cnt <= flash_cnt - 27'd1; // consume el tiempo del destello
      end
    end
  end

  // Salida visible:
  //   - Durante el DESTELLO: solo el/los LED(s) de la tecla pulsada.
  //   - En REPOSO: todo apagado.
  always @(*) begin
    if (flashing)
      leds = flash_mask;
    else
      leds = {N_LEDS{1'b0}};
  end

endmodule
