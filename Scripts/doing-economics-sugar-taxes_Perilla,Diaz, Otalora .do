********** CONFIGURACIÓN INICIAL **********
* Autor: Jerónimo Díaz, Isabella, Camila 
* Descripción: Taller 5 - Doing Economics / Sugar Taxes

* Establecer el directorio de trabajo
global workdir "C:\Users\Cam_p\OneDrive\Documentos\SEMESTRE 2\HACIENDO ECONOMIA\taller 5 - sugar"
cd "$workdir"

///////////////////////////////////////////////////////////////////////////////

********** IMPORTACIÓN DE DATOS Y ETIQUETADO **********

* Importar diccionario de datos para etiquetas
import excel "C:\Users\Cam_p\OneDrive\Documentos\SEMESTRE 2\HACIENDO ECONOMIA\taller 5 - sugar\data\raw\Encuesta de precios de tiendas de Berkeley.xlsx", ///
    sheet("Data Dictionary") firstrow clear

* Crear etiquetas para variables
tempname fh
local N = _N
file open `fh' using "$workdir\script\dolabs.do", write replace
forvalues i = 1/`N' {
    file write `fh' `"label variable `= VariableName[`i']' "`= Description[`i']'""' _newline
}
file close `fh'

///////////////////////////////////////////////////////////////////////////////

* Importar datos principales
import excel "data/raw/Encuesta de precios de tiendas de Berkeley.xlsx", ///
    sheet("Data") firstrow clear

* Aplicar etiquetas de variables
run "$workdir\script\dolabs.do"

describe

********** PROCESAMIENTO DE VARIABLES **********

* Convertir variables categóricas
encode type, gen(type_factor)

* Etiquetas para bebidas gravadas
label define taxed_label 0 "Not Taxed" 1 "Taxed"
label values taxed taxed_label

* Etiquetas para tipos de tienda
label define storetype_label 1 "Large Supermarket" 2 "Small Supermarket" 3 "Pharmacy" 4 "Gas Station"
label values store_type storetype_label

* Corrección de errores en la variable de tiempo
replace time = "MAR2016" if time == "MAR2015"
encode time, gen(time_factor)

* Guardar dataset procesado
save "data/derived/dat.dta", replace

********** ESTADÍSTICAS DESCRIPTIVAS **********

* Número de tiendas únicas
use "data/derived/dat.dta", clear
bysort store_id: gen store_count = _N
bysort product_id: gen product_count = _N

display "Número total de tiendas: " _N
mean store_count, over(store_id)

* Número de productos por tipo y período
collapse (count) nproducts=product_id, by(type time_factor)
reshape wide nproducts, i(type) j(time_factor)
list

********** TABLAS DE FRECUENCIA **********

* Tabla de frecuencia por tipo de tienda y período
use "data/derived/dat.dta", clear
keep if inlist(time_factor,1,2)
collapse (count) nstores=store_id, by(store_type time_factor)
reshape wide nstores, i(store_type) j(time_factor)
list

* Tabla de frecuencia por tipo de tienda y estado del impuesto
use "data/derived/dat.dta", clear
keep if inlist(time_factor, 1, 2)
collapse (count) nproducts=product_id, by(store_type taxed)
reshape wide nproducts, i(store_type) j(taxed)
list

* Tabla de frecuencia por tipo de producto y período
use "$workdir\data\derived.dta", clear
keep if inlist(time_factor, 1, 2)
collapse (count) nproducts=product_id, by(type time_factor)
reshape wide nproducts, i(type) j(time_factor)
list

********** GRÁFICO DE CAMBIO EN PRECIO CON BARRAS AGRUPADAS **********

use "$workdir\data\derived.dta", clear
keep if supp == 0

// Keep only those that we observe the three periods (product-store)
bys product_id store_id: gen hayp1 = time_factor==1
bys product_id store_id: gen hayp2 = time_factor==2
bys product_id store_id: gen hayp3 = time_factor==3

bys product_id store_id: egen hayp1M = max(hayp1)
bys product_id store_id: egen hayp2M = max(hayp2)
bys product_id store_id: egen hayp3M = max(hayp3)

gen period_test = hayp1M*hayp2M*hayp3M
drop hayp1- hayp3M

keep if period_test==1

// Count
table ( store_type ) ( taxed time ) ()
// Conditional means
table ( store_type ) ( taxed time ) (), statistic(mean price_per_oz)


* Would we be able to assess the effect of sugar taxes on product prices by 
* comparing the average price of untaxed goods with that of taxed goods in any 
* given period? Why or why not?

* 4. Using your table from Question 3 ******************************************

* Calculate the change in the mean price after the tax (price in June 2015 minus 
* price in December 2014) for taxed and untaxed beverages, by store type.
* 1. Importar los datos desde Excel
* 2. Limpiar la variable de tiempo
* 1. Importar los datos desde Excel
* 1. Verificar los datos disponibles
* 1. Calcular la diferencia de precios entre periodos
* Llenar los valores dentro de cada grupo
* Llenar los valores dentro de cada grupo
// Crear una variable de tiempo limpia si no existe
cap gen time_clean = substr(time, 1, 3) + substr(time, -4, 4)

// Verificar si la variable se creó correctamente
tab time_clean

// Agrupar por taxed, store_type y time (equivalente a group_by en R)
collapse (count) n=price_per_oz (mean) price_per_oz, by(taxed store_type time)

// Convertir la estructura de datos de larga a ancha (equivalente a spread en R)
reshape wide price_per_oz, i(taxed store_type) j(time) string

// Calcular D1 y D2
gen D1 = price_per_ozJUN2015 - price_per_ozDEC2014

// Agregar los cálculos a la tabla final
collapse (sum) n (mean) price_per_ozDEC2014 price_per_ozJUN2015 price_per_ozMAR2016 D1, by(taxed store_type)

// Aplicar formato: decimales normales en precios y notación científica en D1 y D2
format price_per_ozDEC2014 price_per_ozJUN2015 price_per_ozMAR2016 %9.3f
format D1 %9.3e

// Mostrar la tabla
list taxed store_type n price_per_ozDEC2014 price_per_ozJUN2015 price_per_ozMAR2016 D1, clean
list
* Using the values you calculated in Question 4(a), plot a column chart to show 
* this information (as done in Figure 2 of the journal paper) with store type on 
* the horizontal axis and price change on the vertical axis. Label each axis and 
* data series appropriately. You should get the same values as shown in Figure 2.
* 1. Configurar etiquetas para los tipos de tienda
* 1. Verificar si las etiquetas ya están asignadas
* 1. Crear el gráfico de columnas con colores para bebidas gravadas y no gravadas
* 1. Crear el gráfico de barras agrupadas sin etiquetas numéricas arriba
* 1. Crear el gráfico de barras agrupadas con colores distintos y sin etiquetas de taxed/non-taxed
* 1. Crear el gráfico de barras agrupadas con colores distintos y sin etiquetas de taxed/non-taxed
* Crear la variable de cambio de precio de diciembre 2014 a junio 2015
graph bar (mean) D1, over(taxed, gap(0)) over(store_type, gap(50)) ///
    asyvars bar(1, color(red)) bar(2, color(cyan)) ///
    title("Average price change from Dec 2014 to Jun 2015") ///
    ytitle("Price change (US$/oz)") ///
    legend(order(1 "Taxed" 2 "Non-taxed") title("Beverage Type")) ///
    bargap(0)


*3.2 Before and after comparisons with prices in other areas

import excel using "data/raw/Excel - project 3.2.xls", sheet("Sheet1") firstrow clear
rename location state
replace state = subinstr(state, "-", "_", .)

* Calculate the average price grouped by year, month, state, and tax
collapse (mean) price, by(year month state tax)
reshape wide price, i(year month tax) j(state) string
* Rename variables correctly
rename priceBerkeley Berkeley
rename priceNon_Berkeley Non_Berkeley
*round values 
format Berkeley Non_Berkeley %9.2f 

* Display the table with the values
list year month tax Berkeley Non_Berkeley, sepby(year month)
list

* Crear el gráfico de líneas con formato ajustado
* Configurar el formato de la variable tiempo combinando año y mes
* Configurar el formato de la variable tiempo combinando año y mes
* Configurar el formato de la variable tiempo combinando año y mes
gen time = year + (month - 1) / 12

* Crear el gráfico de líneas con formato ajustado
twoway (line Berkeley time if tax == "Taxed", lcolor(blue) lwidth(medium)) ///
       (line Non_Berkeley time if tax == "Taxed", lcolor(pink) lwidth(medium) lpattern(dot)) ///
       (line Berkeley time if tax == "Non-taxed", lcolor(green) lwidth(medium)) ///
       (line Non_Berkeley time if tax == "Non-taxed", lcolor(orange) lwidth(medium)lpattern(dot)), ///
       title("Average price of taxed and not Berkeley areas") ///
       ytitle("Average price") ///
       xtitle("Time") ///
       legend(order(1 "Taxed (Berkeley)" 2 "Taxed (non-Berkeley)" ///
                    3 "Non-taxed (Berkeley)" 4 "Non-taxed (non-Berkeley)")) ///
       xline(2014.9167, lcolor(gray) lpattern(dot)) ///
       text(4.5 2014.6 "Pre-tax", place(east) size(small)) ///
       text(4.5 2015.3 "Post-tax", place(west) size(small)) ///
       xlabel(2013(0.5)2016) ///
       graphregion(color(white))

