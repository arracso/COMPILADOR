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
    
    public Lib() {
    }
    
    // Imprimim un missatge per pantalla
    public Vector<Long> escriure(char tipus, Long adreca, Boolean saltLinia, Bytecode bc_){
        Vector<Long> trad = new Vector<Long>(12);
        if(tipus == ENTER_){
            
            trad.add(bc_.LDC_W);
            trad.add(bc_.nByte(adreca,2));
            trad.add(bc_.nByte(adreca,1));
            trad.add(bc_.INVOKESTATIC);
            trad.add(bc_.nByte(bc_.mPutInt,2));
            trad.add(bc_.nByte(bc_.mPutInt,1));
        }
        else if(tipus == REAL_){
            trad.add(bc_.LDC_W);
            trad.add(bc_.nByte(adreca,2));
            trad.add(bc_.nByte(adreca,1));
            trad.add(bc_.INVOKESTATIC);
            trad.add(bc_.nByte(bc_.mPutFloat,2));
            trad.add(bc_.nByte(bc_.mPutFloat,1));
        }
        else if(tipus == CAR_){
            trad.add(bc_.LDC_W);
            trad.add(bc_.nByte(adreca,2));
            trad.add(bc_.nByte(adreca,1));
            trad.add(bc_.INVOKESTATIC);
            trad.add(bc_.nByte(bc_.mPutChar,2));
            trad.add(bc_.nByte(bc_.mPutChar,1));
        }
        else if(tipus == BOOL_){
            trad.add(bc_.LDC_W);
            trad.add(bc_.nByte(adreca,2));
            trad.add(bc_.nByte(adreca,1));
            trad.add(bc_.INVOKESTATIC);
            trad.add(bc_.nByte(bc_.mPutBoolean,2));
            trad.add(bc_.nByte(bc_.mPutBoolean,1));
        }
        else if(tipus == STR_){
            trad.add(bc_.LDC_W);
            trad.add(bc_.nByte(adreca,2));
            trad.add(bc_.nByte(adreca,1));
            trad.add(bc_.INVOKESTATIC);
            trad.add(bc_.nByte(bc_.mPutString,2));
            trad.add(bc_.nByte(bc_.mPutString,1));
        }
        if(saltLinia){
            Long barN=bc_.addConstant("C","\n");
            trad.add(bc_.LDC_W);
            trad.add(bc_.nByte(barN,2));
            trad.add(bc_.nByte(barN,1));
            trad.add(bc_.INVOKESTATIC);
            trad.add(bc_.nByte(bc_.mPutChar,2));
            trad.add(bc_.nByte(bc_.mPutChar,1));
        }
        return trad;
    } 
}