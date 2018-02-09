Per poder veure les llibreries s'ha de fer un set de la variable d'entorn CLASSPATH. 
(antlr-runtime-4.7.jar -> llibreries de antlr | . -> .class compilats)

# PATH Temporal
	set PATH=C:\Program Files\Java\jdk1.8.0_111\bin
	set CLASSPATH=antlr-runtime-4.7.jar;.
	// generar recognizer amb ANTLR
	javac *.java
	java Main
	
# PATH Permanent
	setx PATH %PATH%;C:\Program Files\Java\jdk1.8.0_111\bin // Els proxims cops no caldra aquesta linea (compte no fer override de la variable)
	setx CLASSPATH antlr-runtime-4.7.jar // Els proxims cops no caldra aquesta linea
	// generar recognizer amb ANTLR
	javac *.java
	java -cp %CLASSPATH%;. Main [program]
	java -cp . _compilat_

