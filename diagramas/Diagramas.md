# Diagrama del periférico `Teclado - Host`

```mermaid
flowchart
    A([Teclado tiene un byte]) --> B{CLK = 1 y DATA=1}
    B -- No --> C[Guardar byte en buffer de 16]
    C --> B
    B -- Sí --> D[Esperar ≥ 50 µs CLK = 0]
    D --> E[envía la DATA]
    E --> F[Teclado genera flanco de bajada]
    F --> G[Host lee el bit]
    G --> H{Bit 11 enviado,<br/>stop}
    H -- No --> E
    H -- Sí --> I([CLK = 1,Data = 1])
```

# Diagrama del periférico `Host - Teclado`

```mermaid
flowchart
    A([Host quiere enviar]) --> B[CLK = 0]
    B --> C[DATA = 0, bit de start]
    C --> D[Libera CLK]
    D --> E[Teclado genera flanco de subida]
    E --> F[Host actualiza DATA con CLK en bajo]
    F --> G{Bit 11 enviado,<br/>stop}
    G -- No --> E
    G -- Sí --> H[Host libera DATA]
    H --> I[Teclado baja DATA, ACK]
    I --> J([Comando enviado])
```

