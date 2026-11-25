`timescale 1ns / 1ps
//============================================================================
// top_ps2_leds_TB : banco de pruebas del TOP (PS/2 -> RX -> ID -> LEDs).
//
// Inyecta scancodes PS/2 reales con paridad impar y flancos de PS2_CLK,
// igual que un teclado fisico, y verifica que los LEDs (activos en bajo)
// reaccionen a cada tecla de control (make) y NO a las sueltas (break F0).
//============================================================================
module top_ps2_leds_TB;

  reg        clk27;
  reg        rst_n;
  reg        ps2_clk;
  reg        ps2_dat;
  wire [5:0] led_n;

  // LEDs en logica positiva para imprimir facil (placa es activa en bajo)
  wire [5:0] leds = ~led_n;

  // FLASH para simular: 5000 ciclos (en la placa son 8_100_000 ~=0.3s).
  // Mas largo que un send_byte para poder observar el LED "encendido"
  // justo tras la tecla y luego el reposo (apagado) cuando expira.
  top_ps2_leds #(.FLASH_CYCLES(27'd5000)) uut (
    .clk27(clk27), .rst_n(rst_n),
    .ps2_clk(ps2_clk), .ps2_dat(ps2_dat),
    .led_n(led_n)
  );

  // Reloj de 27 MHz (periodo ~37 ns). Uso 36 ns para numeros redondos.
  initial clk27 = 1'b0;
  always #18 clk27 = ~clk27;

  // --- Envio de un bit PS/2 (dato estable, flanco de bajada de ps2_clk) ---
  // El top sincroniza/filtra, asi que mantenemos cada nivel varios ciclos.
  task send_bit;
    input b;
    begin
      ps2_dat = b;
      ps2_clk = 1'b1;
      repeat (12) @(posedge clk27);
      ps2_clk = 1'b0;            // flanco de bajada -> captura
      repeat (12) @(posedge clk27);
      ps2_clk = 1'b1;
      repeat (12) @(posedge clk27);
    end
  endtask

  // --- Envio de un byte PS/2 completo: start + 8 datos (LSB primero) +
  //     paridad impar + stop. El RX procesa 10 bits (start+8+paridad). ---
  task send_byte;
    input [7:0] data;
    integer k;
    reg parity;
    reg [10:0] frame;   // {stop, parity, data[7:0], start}
    begin
      parity = ~^data;                         // paridad impar
      frame  = {1'b1, parity, data, 1'b0};     // stop, par, datos, start
      for (k = 0; k < 10; k = k + 1)           // 10 bits (sin stop)
        send_bit(frame[k]);
      // pequena pausa entre bytes (linea en reposo)
      ps2_clk = 1'b1; ps2_dat = 1'b1;
      repeat (20) @(posedge clk27);
    end
  endtask

  // Reporta el estado de los LEDs tras una accion.
  task show;
    input [8*24:1] etiqueta;
    begin
      $display("[%0t] %0s -> leds=%b (bin, LED6..LED1) led_n=%b",
               $time, etiqueta, leds, led_n);
    end
  endtask

  // Monitor del evento de pulsacion: muestra el instante del destello real.
  always @(posedge clk27) begin
    if (uut.key_stroke)
      $display("[%0t]   >> key_stroke idx=%0d : enciende LED(s) de la tecla ~0.3s",
               $time, uut.id_indice);
  end

  // Espera a que el destello expire (flash de 5000 ciclos) y muestra el reposo.
  task esperar_reposo;
    begin
      repeat (5200) @(posedge clk27);
    end
  endtask

  initial begin
    $dumpfile("top_ps2_leds_TB.vcd");
    $dumpvars(-1, uut);

    // Reset
    rst_n   = 1'b0;
    ps2_clk = 1'b1;
    ps2_dat = 1'b1;
    repeat (10) @(posedge clk27);
    rst_n = 1'b1;
    repeat (10) @(posedge clk27);
    show("tras reset");

    $display("--- Cada tecla: ENCENDIDO (justo tras pulsar) y REPOSO apagado (tras expirar) ---");
    send_byte(8'h1C); show("Left  ON");  esperar_reposo; show("Left  reposo");
    send_byte(8'h23); show("Right ON");  esperar_reposo; show("Right reposo");
    send_byte(8'h1D); show("Up    ON");  esperar_reposo; show("Up    reposo");
    send_byte(8'h1B); show("Down  ON");  esperar_reposo; show("Down  reposo");
    send_byte(8'h5A); show("Start ON");  esperar_reposo; show("Start reposo");
    send_byte(8'h29); show("Select ON"); esperar_reposo; show("Select reposo");

    $display("--- Repetir una tecla: re-enciende su LED y se vuelve a apagar (sin acumular) ---");
    send_byte(8'h1C); show("Left repetido ON (solo LED1)");
    esperar_reposo;   show("Left repetido reposo (todo apagado)");

    $display("--- Break code: soltar tecla NO cuenta ni enciende ---");
    send_byte(8'hF0); show("F0 (break prefix)");
    send_byte(8'h1C); show("1C tras F0 (suelta Left: no enciende)");
    esperar_reposo;   show("reposo tras break (todo apagado)");

    $display("--- Teclas que encienden DOS LEDs ---");
    $display("    A -> los 2 de la IZQUIERDA (LED1+LED2); B -> los 2 de la DERECHA (LED5+LED6)");
    send_byte(8'h3B); show("A ON (LED1+LED2)");  esperar_reposo; show("A reposo");
    send_byte(8'h42); show("B ON (LED5+LED6)");  esperar_reposo; show("B reposo");

    $display("--- Tecla normal tras el break vuelve a encender ---");
    send_byte(8'h1D); show("Up ON");
    esperar_reposo;   show("Up reposo");

    repeat (20) @(posedge clk27);
    $finish;
  end

  // Salvaguarda de tiempo por si algo se cuelga.
  initial begin
    #5_000_000 $display("TIMEOUT"); $finish;
  end

endmodule
