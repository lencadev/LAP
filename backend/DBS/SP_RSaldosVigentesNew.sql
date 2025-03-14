USE [Cobros]
GO
/****** Object:  StoredProcedure [dbo].[SP_RSaldosVigentes]    Script Date: 29/12/2024 9:14:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SP_RSaldosVigentes]
    @ID_CLIENTE INT
AS
BEGIN
    DECLARE @FechaActual DATE;
    SET @FechaActual = GETDATE();

    SET NOCOUNT ON;

    -- Variables para calcular el ajuste de cuotas
    DECLARE @MontoTotal DECIMAL(10, 2);
    DECLARE @NumeroCuotas INT;
    DECLARE @CuotaBase DECIMAL(10, 2);
    DECLARE @Diferencia DECIMAL(10, 2);

    -- Obtener el monto total del préstamo y el número de cuotas restantes
    SELECT TOP 1 
        @MontoTotal = P.Monto, 
        @NumeroCuotas = COUNT(FP.Id)
    FROM FechasPagos FP
    JOIN PlanesPago PP ON FP.PlanId = PP.Id
    JOIN Prestamos P ON PP.Id = P.IdPlan
    WHERE @ID_CLIENTE = P.IdCliente AND P.Estado = 1 AND P.IdEstadoInterno = 2 AND FP.Estado = 0
    GROUP BY P.Monto;

    -- Calcular la cuota base y la diferencia
    SET @CuotaBase = ROUND(@MontoTotal / @NumeroCuotas, 2);
    SET @Diferencia = @MontoTotal - (@CuotaBase * @NumeroCuotas);

    -- Generar el resultado ajustando cuota, capital, mora y totalSVigentes
    SELECT 
        P.Id AS idPrestamo, 
        FP.FechaPago AS fechaVto, 
        FP.Id AS IDfp,

        -- Cálculo de días de mora
        CASE 
            WHEN DATEDIFF(DAY, FP.FechaPago, @FechaActual) > 0 
            THEN DATEDIFF(DAY, FP.FechaPago, @FechaActual) 
            ELSE 0 
        END AS dias,

		 -- Ajuste para la columna capital
        CASE 
            WHEN ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY FP.FechaPago) = @NumeroCuotas 
            THEN CAST(FP.Monto AS DECIMAL(18, 2)) + @Diferencia -- Ajustar el capital de la última cuota
            ELSE CAST(FP.Monto AS DECIMAL(18, 2))
        END AS cuota,

		 -- Ajuste para la columna cuota
        CASE 
            WHEN ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY FP.FechaPago) = @NumeroCuotas 
            THEN @CuotaBase + @Diferencia -- Ajustar la última cuota
            ELSE @CuotaBase
        END AS capital,

		 -- Cálculo del interés corriente
        CASE 
            WHEN CAST((P.Monto * (P.TasaInteres / 100) / PP.CuotasPagar) AS DECIMAL(18, 2)) > (SELECT SUM(Monto) FROM Pagos WHERE IdFechaPago = FP.Id)
                THEN CAST((P.Monto * (P.TasaInteres / 100) / PP.CuotasPagar) AS DECIMAL(18, 2)) - (SELECT SUM(Monto) FROM Pagos WHERE IdFechaPago = FP.Id)
            WHEN CAST((P.Monto * (P.TasaInteres / 100) / PP.CuotasPagar) AS DECIMAL(18, 2)) <= (SELECT SUM(Monto) FROM Pagos WHERE IdFechaPago = FP.Id)
                THEN 0
            ELSE CAST((P.Monto * (P.TasaInteres / 100) / PP.CuotasPagar) AS DECIMAL(18, 2)) 
        END AS intCorriente, 


        -- Cálculo de la mora
        CASE 
            WHEN DATEDIFF(DAY, FP.FechaPago, @FechaActual) > 0 
            THEN (FP.Monto * 0.001) * DATEDIFF(DAY, FP.FechaPago, @FechaActual)
            ELSE 0
        END AS intMora,

        -- Ajuste para la columna totalSVigentes
        CASE 
            WHEN ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY FP.FechaPago) = @NumeroCuotas 
            THEN (FP.Monto + (FP.Monto * 0.001) * 
                CASE 
                    WHEN DATEDIFF(DAY, FP.FechaPago, @FechaActual) > 0 
                    THEN DATEDIFF(DAY, FP.FechaPago, @FechaActual) 
                    ELSE 0 
                END) + @Diferencia -- Ajustar el total de la última cuota
            ELSE FP.Monto + (FP.Monto * 0.001) * 
                CASE 
                    WHEN DATEDIFF(DAY, FP.FechaPago, @FechaActual) > 0 
                    THEN DATEDIFF(DAY, FP.FechaPago, @FechaActual) 
                    ELSE 0 
                END
        END AS totalSVigentes

    FROM FechasPagos FP 
    JOIN PlanesPago PP ON FP.PlanId = PP.Id 
    JOIN Prestamos P ON PP.Id = P.IdPlan 
    WHERE @ID_CLIENTE = P.IdCliente  
        AND P.Estado = 1 
        AND P.IdEstadoInterno = 2  
        AND FP.Estado = 0 
        AND FP.FechaPago >= @FechaActual
    ORDER BY P.Id, FP.FechaPago;
END;
