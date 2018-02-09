/*
 * Gauchola Vilardell, Jaume
 * Raya i Casanova, Òscar
 * Curs 2017-2018 GEINF 4 Compiladors
 */
 
import java.io.*;
import java.lang.Object;
import java.util.Vector;

/* 
 * Aquesta classe engloba tots els metodes de generacio de codi
 * la definicio dels tipus de tokents, etc.
 * D'aquesta manera s'evita repetir codi
 */
public class Lib  {
    public static final char CONST_ = 'x';
    public static final char VAR_ = 'v';
    public static final char FUNC_ = 'f';
    public static final char ACC_ = 'a';

    public static final char ENTER_ = 'I';
    public static final char REAL_ = 'F';
    public static final char CAR_ = 'C';
    public static final char BOOL_ = 'Z';
    public static final char STR_ = 'S';
    
    public Lib(){}
        
    // Imprimim un missatge per pantalla
    public Vector<Long> escriure(char tipus, Bytecode bc_){
        Vector<Long> trad = new Vector<Long>(3);
        trad.add(bc_.INVOKESTATIC);
        if(tipus == ENTER_){
            trad.add(bc_.nByte(bc_.mPutInt,2));
            trad.add(bc_.nByte(bc_.mPutInt,1));
        }
        else if(tipus == REAL_){
            trad.add(bc_.nByte(bc_.mPutFloat,2));
            trad.add(bc_.nByte(bc_.mPutFloat,1));
        }
        else if(tipus == CAR_){
            trad.add(bc_.nByte(bc_.mPutChar,2));
            trad.add(bc_.nByte(bc_.mPutChar,1));
        }
        else if(tipus == BOOL_){
            trad.add(bc_.nByte(bc_.mPutBoolean,2));
            trad.add(bc_.nByte(bc_.mPutBoolean,1));
        }
        else if(tipus == STR_){
            trad.add(bc_.nByte(bc_.mPutString,2));
            trad.add(bc_.nByte(bc_.mPutString,1));
        }
        return trad;
    } 

    
}