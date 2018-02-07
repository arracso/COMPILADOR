import java.io.*;

import org.antlr.v4.runtime.*;

public class Main {

	public static void main(String args[]) throws Exception{
		if(args.length == 0){
			System.out.println("Es requereix un fitxer LANS");
			System.exit(0);
		}
		compiladorLexer lexer = new compiladorLexer(new ANTLRFileStream(args[0]));
		CommonTokenStream tokens = new CommonTokenStream(lexer);
		compiladorParser p = new compiladorParser(tokens);
		p.inici();
	}
}
