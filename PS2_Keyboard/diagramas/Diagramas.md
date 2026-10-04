# Diagrama del periférico `Teclado - Host`

```mermaid
flowchart
    A([Teclado tiene un byte]) --> B{CLK en alto?}
    B -- No --> C[Guardar byte en buffer de 16]
    C --> B
    B -- Sí --> D[Esperar CLK alto, >= 50us]
    D --> E[Teclado pone bit en DATA]
    E --> F[Teclado genera flanco de bajada]
    F --> G[Host lee el bit]
    G --> H{Bit 11 enviado,<br/>stop}
    H -- No --> E
    H -- Sí --> I([Bus vuelve a idle])
```

# Diagrama del periférico `Host - Teclado`

```mermaid
flowchart
    A([Host quiere enviar]) --> B[Baja CLK, >= 100us]
    B --> C[Baja DATA, bit de start]
    C --> D[Libera CLK]
    D --> E[Teclado genera flanco de subida]
    E --> F[Host actualiza DATA con CLK en bajo]
    F --> G{Bit 11 enviado,<br/>stop}
    G -- No --> E
    G -- Sí --> H[Host libera DATA]
    H --> I[Teclado baja DATA, ACK]
    I --> J([Comando enviado])
```

