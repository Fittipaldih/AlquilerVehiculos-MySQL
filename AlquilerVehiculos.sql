CREATE SCHEMA IF NOT EXISTS AlquilerVehiculos;
USE AlquilerVehiculos;
-- CREACION DE TABLAS 
CREATE TABLE IF NOT EXISTS Estado(
id INT PRIMARY KEY NOT NULL,
detalle VARCHAR(15) UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS Marca(
id INT PRIMARY KEY NOT NULL,
nombre VARCHAR(25) UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS Tipo(
id INT PRIMARY KEY NOT NULL,
detalle VARCHAR(25) UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS Provincia(
id INT PRIMARY KEY NOT NULL,
nombre VARCHAR(25) UNIQUE NOT NULL,
idPais INT NOT NULL REFERENCES Pais(id)
);
CREATE TABLE IF NOT EXISTS Vehiculo(
id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
patente VARCHAR(10) UNIQUE NOT NULL,
año YEAR,
plazas INT NOT NULL,
idEstado INT NOT NULL REFERENCES Estado(id),
idMarca INT NOT NULL REFERENCES Marca(id),
idTipo INT NOT NULL REFERENCES Tipo(id)
);
CREATE TABLE IF NOT EXISTS Cliente(
id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
email VARCHAR(50) UNIQUE,
nombreApellido VARCHAR(255) NOT NULL,
domCalle VARCHAR(255),
domAltura INT,
domPiso VARCHAR(10),
idProvincia INT REFERENCES Provincia(id)
);
CREATE TABLE IF NOT EXISTS Pais(
id INT NOT NULL PRIMARY KEY,
nombre VARCHAR(100) NOT NULL UNIQUE 
);
CREATE TABLE IF NOT EXISTS ClienteEmpresa(
idCliente INT PRIMARY KEY NOT NULL REFERENCES Cliente(id),
cuit INT NOT NULL UNIQUE,
rubro VARCHAR(255)
);
CREATE TABLE IF NOT EXISTS ClienteParticular(
idCliente INT PRIMARY KEY NOT NULL REFERENCES Cliente(id),
fechaNac DATE
);
CREATE TABLE IF NOT EXISTS Telefono(
idCliente INT PRIMARY KEY NOT NULL,
numero BIGINT UNSIGNED UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS VehiculoEsAlquiladoPorCliente(
id INT NOT NULL,
idVehiculo INT NOT NULL REFERENCES Vehiculo(id),
idCliente INT NOT NULL REFERENCES Cliente(id),
fecha DATE NOT NULL,
importe DECIMAL(10,2) NOT NULL,
cantidadDias INT NOT NULL,
contratoSeguro BOOLEAN DEFAULT FALSE,
CONSTRAINT PK_VehiculoEsAlquiladoPorCliente PRIMARY KEY (id, idVehiculo, idCliente)
);

-- CARGANDO DATOS DE PRUEBA
INSERT INTO Estado values (1, 'Bueno'), (2,'Regular'), (3, 'Malo');
INSERT INTO Marca values (1, 'Chevrolet'), (2, 'Fiat'), (3, 'Mercedes Benz'); 
INSERT INTO Tipo values (1, 'Sedan'), (2, 'Coupe'), (3, 'Minivan'); 
INSERT INTO Pais values (1, 'Argentina'), (2, 'Brasil');
INSERT INTO Provincia values (1, 'Buenos Aires',1), (2, 'Rio De Janeiro',2), (3, 'Cordoba',1); 

INSERT INTO Vehiculo (patente, año, plazas, idEstado, idMarca, idTipo) VALUES ('AB443WE', 2017, 5, 1, 1, 1),
										('PNP593', 2016, 5, 2, 2, 3),
                                                                           	('AF223PO', 2023, 2, 1, 3, 2);
																		
INSERT INTO Cliente(email, nombreApellido, domCalle, domAltura, domPiso, idProvincia) values 
					('fittipaldi.h@gmail.com', 'Hernan Fittipaldi', 'MiCalle', 1234, 'PB', 1), 
					('mailinvalido@gmail.com', 'ClienteEmpresa 1', 'MiCalle', 1234, '1C', 2), 
					('armanditojunior@gmail.com', 'Armando Paredes', 'MiCalle', 1234, 'PB', 1);
             
INSERT INTO ClienteEmpresa values (2, 7854563123, 'Estudio de Abogacia');
INSERT INTO ClienteParticular VALUES (1, '1996-09-17');
INSERT INTO Telefono VALUES (1, 1122334455), (2, 5544332211);
INSERT INTO VehiculoEsAlquiladoPorCliente values (1,1,1,'2022-02-24', 15000, 2, true),
						(3,2,2,'2000-02-24', 12000, 3, true), 
						(4, 1, 3, '20220521', 10000, 1, false);

-- CONSULTAS
-- 1. Liste nombre de clientes que no realizaron alquiler alguno durante el año 2022
SELECT nombreApellido
FROM cliente
WHERE id NOT IN  ( SELECT va.idCliente
                   FROM VehiculoEsAlquiladoPorCliente va 
		   WHERE year(va.fecha) = 2022);
-- otra forma de resolver la consulta es :                   
SELECT nombreApellido
FROM cliente c
WHERE NOT EXISTS  ( SELECT 1
		    FROM VehiculoEsAlquiladoPorCliente va 
		    WHERE year(va.fecha) = 2022
                    AND c.id = va.idCliente );

-- 2. Liste los nombres de clientes del país “Brasil”, junto al importe total de todos los alquileres efectuados al mismo.
SELECT c.nombreApellido as Cliente, SUM( (va.idCliente = c.id) * va.importe) as ImporteTotalPorAlquileres
FROM cliente c
JOIN provincia pro ON c.idProvincia = pro.id
JOIN pais p ON pro.idPais = p.id
LEFT JOIN VehiculoEsAlquiladoPorCliente va ON va.idCliente = c.id
GROUP BY p.nombre
HAVING p.nombre LIKE 'Brasil';
-- otra forma de resolver la consulta es : 
SELECT c.nombreApellido as Cliente, SUM( (va.idCliente = c.id) * va.importe) as ImporteTotalPorAlquileres
FROM cliente c
JOIN VehiculoEsAlquiladoPorCliente va ON va.idCliente = c.id
WHERE c.idProvincia IN ( SELECT p.id
			 FROM provincia p
			 WHERE p.idPais IN (SELECT pa.id
					    FROM pais pa
					    WHERE pa.nombre LIKE 'BRASIL')
						);
                        
-- 3. Crear un listado de los alquileres realizados durante el año 2022. Por cada alquiler
--    detallar: fecha de alquiler, nombre, provincia y país del cliente, patente del vehículo, marca, tipo y estado de conservación.
SELECT va.fecha, c.nombreApellido as Cliente, pro.nombre as Provincia, pa.nombre as Pais, v.patente as Patente, m.nombre as Marca, e.detalle as Estado, t.detalle as Tipo 
FROM VehiculoEsAlquiladoPorCliente va
JOIN cliente c ON c.id = va.idCliente
JOIN provincia pro ON c.idProvincia = pro.id
JOIN pais pa ON pro.idPais = pa.id
JOIN vehiculo v ON v.id = va.idVehiculo
JOIN marca m ON v.idmarca = m.id
JOIN estado e ON v.idEstado = e.id
JOIN tipo t ON v.idTipo = t.id
WHERE year(va.fecha) = 2022;

-- 4. Liste patente y año de los vehículos alquilados por todos los clientes.
SELECT va.id As AlquilerNum, v.patente as Vehiculo, v.año as AñoVehiculo
FROM vehiculo v
JOIN VehiculoEsAlquiladoPorCliente va ON va.idVehiculo = v.id
GROUP BY va.id; -- para evitar repetidos

-- 5. Elimine todos los alquileres realizados a clientes cuyo nombre comienza con la letra A, donde la fecha de alquiler sea 21/05/2022
--     el vehículo tenga 5 plazas y no se haya contratado seguro.
DELETE FROM vehiculoEsAlquiladoPorCliente WHERE id IN( SELECT * FROM (  SELECT va.id 
									FROM vehiculoEsAlquiladoPorCliente va
									WHERE va.fecha = 20220521
									AND va.contratoSeguro IS FALSE
									AND EXISTS ( SELECT c.id 
										     FROM cliente c 
										     WHERE c.nombreApellido like 'A%'
										     AND va.idCliente = c.id
										     AND EXISTS (SELECT v.id
										     FROM vehiculo v
										     WHERE v.plazas = 5 
										     AND v.id = va.idVehiculo)
										)
							)AS X ) ;
