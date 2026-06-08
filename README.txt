==================================================
  COMO EJECUTAR EL CODIGO  (Solemne 2 - Optimizacion)
==================================================

El codigo esta en el cuaderno:  Solemne_AMPL.ipynb
(modelos AMPL resueltos desde Python con la libreria amplpy)

PASOS (en Google Colab):

 1. Entrar a:  https://colab.research.google.com
 2. Archivo  ->  Subir cuaderno  ->  elige  Solemne_AMPL.ipynb
 3. Entorno de ejecucion  ->  Ejecutar todo
       (la primera celda instala AMPL + el solver HiGHS, demora ~1 min)
 4. Los resultados aparecen debajo de cada celda:
       - Parte 1 (ruteo):        costo optimo  $1.130
       - Parte 2 (scheduling):   makespan      32,5 min
       - Parte 3 (verificacion): operador INFACTIBLE -> mejora $1.130
       - Parte 4 (estocastico):  RP            $1.200
 5. La ULTIMA celda genera y descarga el archivo:
       resultados_solemne.txt   (toda la salida en texto)
