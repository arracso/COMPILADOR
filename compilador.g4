/*
 * Gauchola Vilardell, Jaume
 * Raya i Casanova, Òscar
 * Curs 2017-2018 GEINF 4 Compiladors
 */
 
 grammar compilador;

@header{
    import java.io.*;
    import java.lang.Object;
    import java.util.Vector;
}

@parser::members{
         Lib lib_ = new Lib();
         SymTable<Registre> TS = new SymTable<Registre>(1000);   
         boolean error = false; 
         
         static final Long nLocals = 1000L;
         static final Long maxStack = 10000L;
         
         Long contVar=0L;
         Bytecode bc_ = new Bytecode("_compilat_");
         
         Long msg_llegir_enter = bc_.addConstant("S","Entra un enter    : ");
         Long msg_llegir_real = bc_.addConstant("S","Entra un real    : ");
         Long msg_llegir_car = bc_.addConstant("S","Entra un caracter    : ");
         Long msg_llegir_bool = bc_.addConstant("S","Entra un boolea    : ");
         Long barN = bc_.addConstant("C","\n");
         //override method    
         public void notifyErrorListeners(Token offendingToken, String msg, RecognitionException e) {            
              super.notifyErrorListeners(offendingToken,msg,e);            
              error=true;              
         }  
         
}

///////////////////////////////////////
// Regles Sintactiques i Semantiques //
///////////////////////////////////////

inici 
@init
    {
        // Vector de Long per col.locar el codi del Main
  	Vector<Long> trad=new Vector<Long>(1000);
     }
    : ( p=programa {trad.addAll($p.trad);} EOF)
    {
        if (!error)
        {
            trad.add(bc_.RETURN);
            bc_.addMainCode(maxStack,nLocals,trad);
            bc_.write();
            System.out.println("\nMIDA PILA TREBALL: "+trad.size());
            System.out.println("TOTAL VARIABLES: "+contVar);
            //bc_.show();
        }
    }
    ;

//Programa
programa returns [Vector<Long> trad]
@init{$trad = new Vector<Long>(1000);}
        :  TK_PC_PROGRAMA TK_IDENT
                decl_constants? 
                defi_tipus? 
                decl_variables?
                decl_acciofuncio*
                (sen=sentencia{$trad.addAll($sen.trad);})*
            (
                TK_PC_IMPLEMENT
                impl_acciofuncio+
            )?
            TK_PC_FPROGRAMA
         ;

// Estructura declaracio constants 
decl_constants
    //@init{System.out.println("+ 'decl_constants'");}
    //@after{System.out.println("- 'decl_constants'");}
    :    TK_PC_CONST
                    (
                        t=tipus_basic id1=TK_IDENT TK_OP_POINTS l1=literal_tipus_basic
                        {
                            if($t.tipus != $l1.tipus){
                                 error=true;
                                 System.out.println("Error de tipus a la linia " + $id1.line+ "\nIDENT: '"+$id1.text+"' ha de ser de tipus '"+$t.tipus+"'.");
                                 System.exit(-1);
                            }else if(TS.existeix($id1.text)){
                                error=true;
                                System.out.println("Error de constant a la linia " + $id1.line+ "\nCONSTANT: '"+$id1.text+"' ja declarada.");
                                System.exit(-1);
                            }else{
				Long addr = bc_.addConstName($id1.text,String.valueOf($t.tipus),$l1.text.replace("'",""));
                                TS.inserir($id1.text,new Registre($id1.text,$t.tipus, lib_.CONST_,addr));
                            }
                        }
                        (TK_OP_COMA id2=TK_IDENT TK_OP_POINTS l2=literal_tipus_basic
                        {
                            if($t.tipus != $l2.tipus){
                                 error=true;
                                 System.out.println("Error de tipus a la linia " + $id2.line+ "\nIDENT: '"+$id2.text+"' ha de ser de tipus '"+$t.tipus+"'.");
                                 System.exit(-1);
                            }else if(TS.existeix($id2.text)){
                                error=true;
                                System.out.println("Error de constant a la linia " + $id2.line+ "\nCONSTANT: '"+$id2.text+"' ja declarada.");
                                System.exit(-1);
                            }else{
				Long addr = bc_.addConstName($id2.text,String.valueOf($t.tipus),$l2.text.replace("'",""));
                                TS.inserir($id2.text,new Registre($id2.text,$t.tipus, lib_.CONST_, addr));
                            }
                        }
                        )* TK_OP_SEMICOL
                    )+
                    TK_PC_FCONST
                ;

literal_tipus_basic returns [char tipus]  
    :   (ent=TK_ENTER { $tipus = lib_.ENTER_;}
      | rea=TK_REAL  { $tipus = lib_.REAL_; }
      | boo=TK_BOOL  { $tipus = lib_.BOOL_; }
      | car=TK_CAR   { $tipus = lib_.CAR_; }
        ) 
    ;

// Estructura declaracio tipus
tipus_general returns [char tipus]
    //@init{ System.out.println("Entrem a la regla 'tipus_general'");}
    //@after{System.out.println("Sortim de la regla 'tipus_general'");}
    :   (   tip=tipus_basic { $tipus = $tip.tipus; }
        |   id=TK_IDENT
            {   
                if(!TS.existeix($id.text)){
                    error=true;
                    System.out.println("Error de tipus a la linia " + $id.line+
                    "\nIDENT: '"+$id.text+"' no declarat.");
                    System.exit(-1);
                }else{
                    $tipus = TS.obtenir($id.text).getTipus();
                }
             }
        )
    ;

tipus_basic returns [char tipus]
    //@init{ System.out.println("Entrem a la regla 'tipus_basic'");}
    //@after{System.out.println("Sortim de la regla 'tipus_basic'");}
    :   ( TK_PC_ENTER   { $tipus = lib_.ENTER_; }
        | TK_PC_CAR     { $tipus = lib_.CAR_; }
        | TK_PC_REAL    { $tipus = lib_.REAL_; }
        | TK_PC_BOOL    { $tipus = lib_.BOOL_; }
        )
    ;

defi_tipus :    TK_PC_TIPUS
                    (TK_IDENT TK_OP_POINTS constr_tipus TK_OP_SEMICOL)+
                TK_PC_FTIPUS
           ;

constr_tipus : (tipus_basic | constr_vector | constr_tupla) ;

constr_vector : TK_PC_VECTOR expressio TK_PC_TO expressio TK_PC_FROM tipus_basic 
              ;

constr_tupla :  TK_PC_TUPLA
                    (TK_IDENT TK_OP_POINTS tipus_basic TK_OP_SEMICOL)+
                TK_PC_FTUPLA
             ;

// [FER] Estructura declaracio varibales 
decl_variables locals [ArrayList<String> idList]
    //@init{ System.out.println("Entrem a la regla 'decl_variables'");}
    //@after{System.out.println("Sortim de la regla 'decl_variables'");}
    :   TK_PC_VAR
            ( id=TK_IDENT {
                if(TS.existeix($id.text)){
                    error=true;
                    System.out.println("Error de variable a la linia " + $id.line + "\nVARIABLE: '"+$id.text+"' ja declarada.");
                    System.exit(-1);
                }else{
                    $idList = new ArrayList<>();
                    $idList.add($id.text);
                }
            }
            ( TK_OP_COMA id2=TK_IDENT{
                if(TS.existeix($id2.text)){
                    error=true;
                    System.out.println("Error de variable a la linia " + $id2.line + "\nVARIABLE: '"+$id2.text+"' ja declarada.");
                    System.exit(-1);
                }else{
                    $idList.add($id2.text);
                }
            })* 
            TK_OP_POINTS tip=tipus_general TK_OP_SEMICOL {
                for(int i=0;i<$idList.size();i++){
                    TS.inserir($idList.get(i),new Registre($idList.get(i),$tip.tipus, lib_.VAR_,contVar++));
                }
            })+
        TK_PC_FVAR
    ;

// Estructura declaracio accions i funcions
decl_acciofuncio : (decl_accio | decl_funcio) ;
decl_accio : TK_PC_ACCIO TK_IDENT 
             TK_OP_LPAREN param_formals? TK_OP_RPAREN TK_OP_SEMICOL 
           ;

decl_funcio : TK_PC_FUNCIO TK_IDENT 
              TK_OP_LPAREN param_formals? TK_OP_RPAREN 
              TK_PC_RETURNS tipus_basic TK_OP_SEMICOL 
            ;

// --- Estructura param formals
param_formals : (TK_PC_ENT | TK_PC_ENTSORT)? tipus_general TK_IDENT 
                (TK_OP_COMA (TK_PC_ENT | TK_PC_ENTSORT)? tipus_general TK_IDENT)* 
              ;

// Estructura implementafcio funcio i accions
impl_acciofuncio :  (impl_accio | impl_funcio) ;

impl_accio :    TK_PC_ACCIO TK_IDENT TK_OP_LPAREN param_formals? TK_OP_RPAREN
                    decl_variables?
                    sentencia*
                TK_PC_FACCIO
           ;

impl_funcio :   TK_PC_FUNCIO TK_IDENT TK_OP_LPAREN param_formals? TK_OP_RPAREN TK_PC_RETURNS tipus_basic
                    decl_variables?
                    sentencia*
                    TK_PC_RETURNS expressio TK_OP_SEMICOL
                TK_PC_FFUNCIO
            ;

// Estructura Sentencies
sentencia returns [Vector<Long> trad]
@init{}
@after{}
          : ass=assignacio { $trad = $ass.trad;}
          | cri=crida_accio { $trad = $cri.trad;}
          | con=condicional { $trad = $con.trad;}
          | buc=bucle { $trad = $buc.trad;}
          | pe=per { $trad = $pe.trad;}
          | esc=escriure { $trad = $esc.trad;}
          | lleg=llegir { $trad = $lleg.trad;}        
          ;

// [FER][DONE] assignacio (NO FET tupla i vector)
assignacio returns [Vector<Long> trad] locals [char tipus, Registre id]
    @init{System.out.println("+ 'assignacio'");}
    @after{System.out.println("- 'assignacio'");}
    : 
            var=TK_IDENT 
            { 
                    if(!TS.existeix($var.text)){ // si la variable no existeix donem error
                        error=true;
                        System.out.println("Error assignacio a la linia " + $var.line+
                        "\nVARIABLE: '"+$var.text+"' no declarada.");
                        System.exit(-1);
                    }
                    $id = TS.obtenir($var.text);
                    if(!$id.modificable())
                    {
                        error=true;
                        System.out.println("Error assignacio a la linia " + $var.line+
                        "\nIDENT: '"+$var.text+"' no modificable.");
                        System.exit(-1);
                    }
                    $tipus = $id.getTipus();
            } 
            ( punt=TK_OP_POINT TK_IDENT  //Tupla [NO FET]
              {
                    error=true;
                    System.out.println("Error assignacio a la linia " + $punt.line+
                    "\nTUPLES NO FETES.");
                    System.exit(-1);
              } 
            | lclaud=TK_OP_LKEY expressio TK_OP_RKEY //Vector [NO FET]
              {
                    error=true;
                    System.out.println("Error assignacio a la linia " + $lclaud.line+
                    "\nVECTORS NO FETS.");
                    System.exit(-1);
              } 
            )? igual=TK_OP_ASSIGN exp=expressio dosPunts=TK_OP_SEMICOL
            {
                $trad = $exp.trad;
                if($exp.tipus != $tipus){ // si veiem que no tenen el mateix tipus donem error
                    error=true;
                    System.out.println("Error assignacio a la linia " + $igual.line+
                    "\nASSIGNACIO DE TIPUS DIFERENTS.\n"+
                    $exp.text+": "+$exp.tipus+"\n"+$tipus);
                    System.exit(-1);
                }
                if(!$id.teValor())
                    $id.putValor();            
                if($tipus == lib_.ENTER_)
                {
                    $trad.add(bc_.ISTORE);
                    $trad.add($id.getAdreca());
                }
                else if($tipus == lib_.REAL_)
                {
                    $trad.add(bc_.FSTORE);
                    $trad.add($id.getAdreca());
                }
                else if($tipus == lib_.CAR_)
                {
                    $trad.add($id.getAdreca());
                    
                    $trad.add(bc_.CASTORE);
                }
                else if($tipus == lib_.BOOL_)
                {
                    $trad.add(bc_.BASTORE);
                    $trad.add($id.getAdreca());
                }
            }
           ;

// --- crida accio
crida_accio returns [Vector<Long> trad]
    @init{ $trad = new Vector<Long>(0);
          /*System.out.println("+ 'crida_accio'");*/}
    //@after{System.out.println("- 'crida_accio'");}
    :  TK_IDENT TK_OP_LPAREN param_reals? TK_OP_RPAREN TK_OP_SEMICOL 
            ;
param_reals : expressio (TK_OP_COMA expressio)* ;

// [FER] --- estructura condicional
condicional returns [Vector<Long> trad] locals [Vector<Long> trad1, Vector<Long> trad2]
    @init
    {
        $trad = new Vector<Long>(10);
        $trad1 = new Vector<Long>(5);
        $trad2 = new Vector<Long>(5);
    }
    @after{}
    :   c=TK_PC_IF e=expressio { $trad.addAll($e.trad); } TK_PC_THEN
        {
            if($e.tipus != lib_.BOOL_){
                error=true;
                System.out.println("Error condicional a la linia " + $c.line+ "\nL'EXPRESSIO NO ES DE TIPUS BOLEA.");
                System.exit(-1);
            }
        }
            (s1=sentencia { $trad1.addAll($s1.trad); })*
            {
                Long salt1 = new Long(2 + $trad1.size() + 3 + 1); // Bytes + Sentencies + (GOTO + Bytes) + 1
                $trad.add(bc_.IFEQ);
                $trad.add(bc_.nByte(salt1,2));
                $trad.add(bc_.nByte(salt1,1));
                $trad.addAll($trad1);
            }
        ( TK_PC_ELSE
            (s2=sentencia { $trad2.addAll($s2.trad); })*)?
            {
                Long salt2 = new Long(2 + $trad2.size() + 1); // Bytes + Sentencies + 1
                $trad.add(bc_.GOTO);
                $trad.add(bc_.nByte(salt2,2));
                $trad.add(bc_.nByte(salt2,1));
                $trad.addAll($trad2);
            }
        TK_PC_FIF
    ;

// [FER] --- estructura mentre
bucle returns [Vector<Long> trad] locals [Vector<Long> trad2]
    @init
    {
        $trad = new Vector<Long>(10);
        $trad2 = new Vector<Long>(5);
    }
    @after{ }
    :   TK_PC_WHILE
            (s1=sentencia { $trad.addAll($s1.trad); })*
        c=TK_PC_EXITIF e=expressio { $trad.addAll($e.trad); } TK_OP_SEMICOL
        {
            if($e.tipus != lib_.BOOL_){
                error=true;
                System.out.println("Error bucle mentre a la linia " + $c.line+ "\nL'EXPRESSIO NO ES DE TIPUS BOLEA.");
                System.exit(-1);
            }
        }
            (s2=sentencia { $trad2.addAll($s2.trad); })*
            {
                Long salt1 = new Long(2 + $trad2.size() + 3 + 1); // Bytes + Sentencies + (GOTO + Bytes) + 1
                $trad.add(bc_.IFNE);
                $trad.add(bc_.nByte(salt1,2));
                $trad.add(bc_.nByte(salt1,1));
                $trad.addAll($trad2);
            }
        TK_PC_FWHILE
        {
            Long salt2 = new Long(-$trad.size()); // Per tornar al prinipi saltem cap amunt totes les instruccions
            $trad.add(bc_.GOTO);
            $trad.add(bc_.nByte(salt2,2));
            $trad.add(bc_.nByte(salt2,1));
        }
    ;

// [FER] --- estructura per
per returns [Vector<Long> trad] locals [Registre regIDEN]
    @init{ $trad = new Vector<Long>(0);
          /*System.out.println("+ 'per'");*/}
    //@after{System.out.println("- 'per'");}
    :   f=TK_PC_FOR (id=TK_IDENT TK_OP_ASSIGN e1=expressio) TK_PC_TO e2=expressio TK_PC_DO
        {
            if(!TS.existeix($id.text))
            {
                error=true;
                System.out.println("Error bucle per a la linia " + $f.line+"\n"+
                "IDEN: '"+$id.text+"' no declarat.");
                System.exit(-1);
            }
            $regIDEN = TS.obtenir($id.text);
            if(!$regIDEN.modificable())
            {
                error=true;
                System.out.println("Error bucle per a la linia " + $f.line+"\n"+
                "IDEN: '"+$id.text+"' no modificable.");
                System.exit(-1);
            }
            else if($e1.tipus != lib_.ENTER_ || $e1.tipus != $e2.tipus || $regIDEN.getTipus() != $e1.tipus){
                error=true;
                System.out.println("Error de TIPUS en el PER per a la linia " + $f.line+"\n");
                System.exit(-1);
            }
        }
        sentencia*
      TK_PC_FFOR
    ;

// [FER GEN CODI] --- estructura entrades sortides
escriure returns [Vector<Long> trad] locals [Boolean saltlinia]
@init{  $saltlinia = false;
        System.out.println("+ 'escriure'");
        $trad = new Vector<Long>(30);
      }
@after{
        if($saltlinia){ 
            $trad.add(bc_.LDC_W);
            $trad.add(bc_.nByte(barN,2));
            $trad.add(bc_.nByte(barN,1));
            $trad.add(bc_.INVOKESTATIC);
            $trad.add(bc_.nByte(bc_.mPutChar,2));
            $trad.add(bc_.nByte(bc_.mPutChar,1));
        }
       System.out.println("- 'escriure'");
     }
    : (TK_PC_WRITE | TK_PC_WRITELINE {$saltlinia = true;}) tk=TK_OP_LPAREN 
      (exp=expressio 
        {
            $trad.addAll($exp.trad);
            $trad.addAll(lib_.escriure($exp.tipus, bc_));
        }
      | str=TK_STRING
        {
            Long adreca = bc_.addConstant(String.valueOf(lib_.STR_),$str.text.substring(1,$str.text.length()-1));
            $trad.add(bc_.LDC_W);
            $trad.add(bc_.nByte(adreca,2));
            $trad.add(bc_.nByte(adreca,1));
            $trad.addAll(lib_.escriure(lib_.STR_, bc_));
        }      
      ) (TK_OP_COMA 
      (exp2=expressio
        {
            $trad.addAll($exp2.trad);
            $trad.addAll(lib_.escriure($exp2.tipus, bc_));
        }
      | str2=TK_STRING
        {   
            Long adreca = bc_.addConstant(String.valueOf(lib_.STR_),$str2.text.substring(1,$str2.text.length()-1));
            $trad.add(bc_.LDC_W);
            $trad.add(bc_.nByte(adreca,2));
            $trad.add(bc_.nByte(adreca,1));
            $trad.addAll(lib_.escriure(lib_.STR_, bc_));
        }
      ))* TK_OP_RPAREN TK_OP_SEMICOL ;

llegir returns [Vector<Long> trad]
    @init{ $trad = new Vector<Long>(0);
          /*System.out.println("+ 'llegir'");*/}
    //@after{System.out.println("- 'llegir'");}
    : lin=TK_PC_READ TK_OP_LPAREN id=TK_IDENT TK_OP_RPAREN TK_OP_SEMICOL
         {
            if(!TS.existeix($id.text))
            {
                error=true;
                System.out.println("Error llegir per a la linia " + $lin.line+"\n"+
                "IDENT: '"+$id.text+"' no existeix.");
                System.exit(-1); 
            }
            Registre r = TS.obtenir($id.text);
            if(!r.modificable())
            {
                error=true;
                System.out.println("Error llegir per a la linia " + $lin.line+"\n"+
                "IDENT: '"+$id.text+"' no es modificable.");
                System.exit(-1); 
            }
            if(r.getTipus()==lib_.ENTER_)
            {   
                // Entrar un enter 
                $trad.add(bc_.LDC_W);
                $trad.add(bc_.nByte(msg_llegir_enter,2));
                $trad.add(bc_.nByte(msg_llegir_enter,1));
                $trad.add(bc_.INVOKESTATIC);
                $trad.add(bc_.nByte(bc_.mPutString,2));
                $trad.add(bc_.nByte(bc_.mPutString,1));
                $trad.add(bc_.INVOKESTATIC);
                $trad.add(bc_.nByte(bc_.mGetInt,2));
                $trad.add(bc_.nByte(bc_.mGetInt,1));
	   	$trad.add(bc_.ISTORE);
	   	$trad.add(r.getAdreca());
            }
            else if(r.getTipus()==lib_.REAL_)
            {
                // Entrar un real  
                $trad.add(bc_.LDC_W);
                $trad.add(bc_.nByte(msg_llegir_real,2));
                $trad.add(bc_.nByte(msg_llegir_real,1));
                $trad.add(bc_.INVOKESTATIC);
                $trad.add(bc_.nByte(bc_.mPutString,2));
                $trad.add(bc_.nByte(bc_.mPutString,1));
                $trad.add(bc_.INVOKESTATIC);
                $trad.add(bc_.nByte(bc_.mGetFloat,2));
                $trad.add(bc_.nByte(bc_.mGetFloat,1));
	   	$trad.add(bc_.ISTORE);
	   	$trad.add(r.getAdreca());
            }
            else if(r.getTipus()==lib_.CAR_)
            {
                Long refArray = bc_.addArrayDef(0,String.valueOf(lib_.CAR_));
                // Long adrInt = bc_.addConstant(String.valueOf(lib_.ENTER_), r.getAdreca().toString());
                // Entrar un caracter  
                $trad.add(bc_.LDC_W);
                $trad.add(bc_.nByte(msg_llegir_car,2));
                $trad.add(bc_.nByte(msg_llegir_car,1));
                $trad.add(bc_.INVOKESTATIC);
                $trad.add(bc_.nByte(bc_.mPutString,2));
                $trad.add(bc_.nByte(bc_.mPutString,1));
                // es queixa de que no troba un integer....
                $trad.add(bc_.INVOKESTATIC);
                $trad.add(bc_.nByte(bc_.mGetChar,2));
                $trad.add(bc_.nByte(bc_.mGetChar,1));
                $trad.add(bc_.BIPUSH);
                $trad.add(r.getAdreca());
                $trad.add(bc_.LDC_W);
                $trad.add(bc_.nByte(refArray,2));
                $trad.add(bc_.nByte(refArray,1));
                $trad.add(bc_.CASTORE);
                
                
            }
            else if(r.getTipus()==lib_.BOOL_)
            {
                // Entrar un real  
                $trad.add(bc_.LDC_W);
                $trad.add(bc_.nByte(msg_llegir_bool,2));
                $trad.add(bc_.nByte(msg_llegir_bool,1));
                $trad.add(bc_.INVOKESTATIC);
                $trad.add(bc_.nByte(bc_.mPutString,2));
                $trad.add(bc_.nByte(bc_.mPutString,1));
	   	$trad.add(bc_.CASTORE);
                $trad.add(bc_.INVOKESTATIC);
                $trad.add(bc_.nByte(bc_.mGetBoolean,2));
                $trad.add(bc_.nByte(bc_.mGetBoolean,1));
	   	$trad.add(r.getAdreca());
                $trad.add(bc_.addArrayDef(1,String.valueOf(lib_.CAR_)));
            }
            else
            {
                error=true;
                System.out.println("ANOMALIA EN: " + $lin.line+"\nDe quin tipus es?: "+$id.text);
                System.exit(-1);
            }
            if(!r.teValor())
                r.putValor();
                                         
         };


// Estructrura expressions
// --- expresions booleanes
expressio returns [Vector<Long> trad, char tipus, Long adreca]
    @init{ 
          System.out.println("+ 'expressio'");
          $adreca = -1L;
         }
    @after{System.out.println("- 'expressio'");}
    : t1=exprRelacionals 
      { 
        $tipus = $t1.tipus; 
        $adreca = $t1.adreca;
        $trad = $t1.trad;
      }
        ( op=(TK_OP_AND | TK_OP_OR) t2=exprRelacionals {
            if($t1.tipus != lib_.BOOL_ || $t2.tipus != lib_.BOOL_){
                error=true;
                System.out.println("Error de booleans detectat a la linia " + $op.line);
                System.exit(-1);
            }
            $trad.addAll($t2.trad);
            if($op.text.equals("&"))
                $trad.add(bc_.IAND);
            else
                $trad.add(bc_.IOR);
        })*
    ;

// --- expresions relacionals
exprRelacionals returns [Vector<Long> trad, char tipus, Long adreca] locals [char tip1, char tip2]
@init{$adreca = -1L;}
    : t1=exprArit 
      {
        $tipus = $t1.tipus; 
        $tip1 = $t1.tipus;
        $adreca = $t1.adreca;
        $trad = $t1.trad;
      }
        ( op=(TK_OP_LESSOREQUAL | TK_OP_MOREOREQUAL | TK_OP_EQUAL | TK_OP_NOTEQUAL | TK_OP_LESS | TK_OP_MORE) t2=exprArit {
            if(($t1.tipus == lib_.ENTER_ || $t1.tipus == lib_.REAL_) && ($t2.tipus == lib_.ENTER_ || $t2.tipus == lib_.REAL_)){
                $tipus = lib_.BOOL_;
            }else if($t1.tipus == $t2.tipus && ($op.text == "==" || $op.text == "/=")){
                $tipus = lib_.BOOL_;
            }else{
                error=true;
                System.out.println("Error de relacionals detectat a la linia " + $op.line+"\n"+
                $t1.text+": "+$t1.tipus+"\n"+$t2.text+": "+$t2.tipus);
                System.exit(-1);
            }
            $tip2 = $t2.tipus;
            // per fer les operacions relacionals, per forca hem de tenir reals
            if($t1.tipus == lib_.ENTER_){
                $trad.add(bc_.I2F);
                $tip1 = lib_.REAL_;
            }
            $trad.addAll($t2.trad);
            if($t2.tipus == lib_.ENTER_){
                $tip2 = lib_.REAL_;
                $trad.add(bc_.I2F);
            }
            if($tip1 != $tip2)
            {
                error=true;
                System.out.println("Error de relacionals detectat a la linia " + $op.line+"\n"+
                $t1.text+": "+$t1.tipus+"\n"+$t2.text+": "+$t2.tipus);
                System.exit(-1);
            }
            
            // FCMPG real1,real2: real1<real2 = -1,,,,real1=real2=0,,,,,real1>real2=1
            // real1=t2   real2 = t1
            $trad.add(bc_.FCMPG);
            if($op.text.equals("=="))
            {
                Long salt1 = 8L; // 2 bytes + 2 de afegir a la pila + 3 de goto + 1 de linia seguent
                Long salt2 = 5L; // 2 bytes + 2 de afegir a la pila + 1 de linia seguent
                $trad.add(bc_.IFEQ);
                $trad.add(bc_.nByte(salt1,2));
                $trad.add(bc_.nByte(salt1,1));
                // Afegir 0 a la pila
                $trad.add(bc_.BIPUSH);
                $trad.add(0L);
                $trad.add(bc_.GOTO);
                $trad.add(bc_.nByte(salt2,2));
                $trad.add(bc_.nByte(salt2,1));
                // Afegir 1 a la pila
                $trad.add(bc_.BIPUSH);
                $trad.add(1L);
            }
            else if($op.text.equals("/="))
            {
                Long salt1 = 8L; // 2 bytes + 2 de afegir a la pila + 3 de goto + 1 de linia seguent
                Long salt2 = 5L; // 2 bytes + 2 de afegir a la pila + 1 de linia seguent
                $trad.add(bc_.IFNE);
                $trad.add(bc_.nByte(salt1,2));
                $trad.add(bc_.nByte(salt1,1));
                // Afegir 0 a la pila
                $trad.add(bc_.BIPUSH);
                $trad.add(0L);
                $trad.add(bc_.GOTO);
                $trad.add(bc_.nByte(salt2,2));
                $trad.add(bc_.nByte(salt2,1));
                // Afegir 1 a la pila
                $trad.add(bc_.BIPUSH);
                $trad.add(1L);
            }
            if($t1.tipus == lib_.CAR_ || $t1.tipus == lib_.BOOL_ || $t2.tipus == lib_.CAR_ || $t1.tipus == lib_.BOOL_)
            {
                error=true;
                System.out.println("Error de relacionals detectat a la linia " + $op.line+
                ".\n NO ES PERMET AQUEST TIPUS PER A AQUESTES OPERACIONS\n"+
                $t1.text+": "+$t1.tipus+"\n"+$t2.text+": "+$t2.tipus);
                System.exit(-1);
            }
            if($op.text.equals("<"))
            {
                Long salt1 = 8L; // 2 bytes + 2 de afegir a la pila + 3 de goto + 1 de linia seguent
                Long salt2 = 5L; // 2 bytes + 2 de afegir a la pila + 1 de linia seguent
                $trad.add(bc_.IFLT);
                $trad.add(bc_.nByte(salt1,2));
                $trad.add(bc_.nByte(salt1,1));
                // Afegir 0 a la pila
                $trad.add(bc_.BIPUSH);
                $trad.add(0L);
                $trad.add(bc_.GOTO);
                $trad.add(bc_.nByte(salt2,2));
                $trad.add(bc_.nByte(salt2,1));
                // Afegir 1 a la pila
                $trad.add(bc_.BIPUSH);
                $trad.add(1L);
            }
            else if($op.text.equals(">"))
            {
                Long salt1 = 8L; // 2 bytes + 2 de afegir a la pila + 3 de goto + 1 de linia seguent
                Long salt2 = 5L; // 2 bytes + 2 de afegir a la pila + 1 de linia seguent
                $trad.add(bc_.IFGT);
                $trad.add(bc_.nByte(salt1,2));
                $trad.add(bc_.nByte(salt1,1));
                // Afegir 0 a la pila
                $trad.add(bc_.BIPUSH);
                $trad.add(0L);
                $trad.add(bc_.GOTO);
                $trad.add(bc_.nByte(salt2,2));
                $trad.add(bc_.nByte(salt2,1));
                // Afegir 1 a la pila
                $trad.add(bc_.BIPUSH);
                $trad.add(1L);
            }
            else if($op.text.equals("<="))
            {
                Long salt1 = 8L; // 2 bytes + 2 de afegir a la pila + 3 de goto + 1 de linia seguent
                Long salt2 = 5L; // 2 bytes + 2 de afegir a la pila + 1 de linia seguent
                $trad.add(bc_.IFLE);
                $trad.add(bc_.nByte(salt1,2));
                $trad.add(bc_.nByte(salt1,1));
                // Afegir 0 a la pila
                $trad.add(bc_.BIPUSH);
                $trad.add(0L);
                $trad.add(bc_.GOTO);
                $trad.add(bc_.nByte(salt2,2));
                $trad.add(bc_.nByte(salt2,1));
                // Afegir 1 a la pila
                $trad.add(bc_.BIPUSH);
                $trad.add(1L);
            }
            else if($op.text.equals(">="))
            {
                Long salt1 = 8L; // 2 bytes + 2 de afegir a la pila + 3 de goto + 1 de linia seguent
                Long salt2 = 5L; // 2 bytes + 2 de afegir a la pila + 1 de linia seguent
                $trad.add(bc_.IFGE);
                $trad.add(bc_.nByte(salt1,2));
                $trad.add(bc_.nByte(salt1,1));
                // Afegir 0 a la pila
                $trad.add(bc_.BIPUSH);
                $trad.add(0L);
                $trad.add(bc_.GOTO);
                $trad.add(bc_.nByte(salt2,2));
                $trad.add(bc_.nByte(salt2,1));
                // Afegir 1 a la pila
                $trad.add(bc_.BIPUSH);
                $trad.add(1L);
            }
            
        })* 
    ;

// --- expresions suma resta. No funciona per a situacions  I+F(+F)*, si prioritses loperacio posant parentesis si
exprArit returns [Vector<Long> trad, char tipus, Long adreca]
@init{$adreca = -1L;}
    : t1=exprArit2 
      { 
        System.out.println("T1: "+$t1.text+"   tip: "+$t1.tipus);
        // agafem les operacions de t1, en el top de lapila contrindra el valor de t1
        $tipus = $t1.tipus;
        $trad = $t1.trad;
      }
        ( op=(TK_OP_PLUS | TK_OP_MINUS) t2=exprArit2 
          {
            System.out.println("T2: "+$t2.text+"   tip: "+$t2.tipus);
            // Si no son ni enters ni reals
            if(($t1.tipus != lib_.ENTER_ && $t1.tipus != lib_.REAL_) || ($t2.tipus != lib_.ENTER_ && $t2.tipus != lib_.REAL_)){ 
                error=true;
                System.out.println("Error de aritmetic detectat a la linia " + $op.line+
                "\n"+$t1.text+": "+$t1.tipus+
                "\n"+$t2.text+": "+$t2.tipus);
                System.exit(-1);
            }
            if ($t2.tipus == lib_.REAL_){
                if($tipus == lib_.ENTER_)
                {   
                    $trad.add(bc_.I2F);
                }
                $tipus = lib_.REAL_;
            }
            // Agafem les operacions de t2
            $trad.addAll($t2.trad);
            if($tipus == lib_.REAL_ && $t2.tipus == lib_.ENTER_)
            {
                $trad.add(bc_.I2F);
            }
            // fem les operacions SUMA o RESTA, en el top de la pila tindrem els 2 valors
            if($op.text.equals("+"))
            {
                if($tipus == lib_.ENTER_) 
                    $trad.add(bc_.IADD);
                else
                    $trad.add(bc_.FADD);
            }
            else
            {
                if($tipus == lib_.ENTER_) 
                    $trad.add(bc_.ISUB);
                else
                    $trad.add(bc_.FSUB);
            }
            
        })*
    ;

// --- expresions producte divisio
exprArit2 returns [Vector<Long> trad, char tipus, Long adreca]
@init{$adreca = -1L;}
    : t1=expUnari  
      { 
        $tipus = $t1.tipus; 
        $adreca = $t1.adreca;
        $trad = $t1.trad;
      }
        ( op=(TK_OP_STAR | TK_OP_BAR | TK_OP_CBAR | TK_OP_PERCENT) t2=expUnari {
            if(($t1.tipus != lib_.ENTER_ && $t1.tipus != lib_.REAL_) || ($t2.tipus != lib_.ENTER_ && $t2.tipus != lib_.REAL_)){ // Si no son ni enters ni reals
                error=true;
                System.out.println("Error de aritmetic_2 detectat a la linia " + $op.line);
                System.exit(-1);
            }
            if ($t2.tipus == lib_.REAL_){
                if($tipus == lib_.ENTER_)
                {   
                    $trad.add(bc_.I2F);
                }
                $tipus = lib_.REAL_;
            }
            // Agafem les operacions de t2
            $trad.addAll($t2.trad);
            if($tipus == lib_.REAL_ && $t2.tipus == lib_.ENTER_)
            {
                $trad.add(bc_.I2F);
            }
            if($op.text.equals("*"))
            {
                if($tipus == lib_.ENTER_) 
                    $trad.add(bc_.IMUL);
                else
                    $trad.add(bc_.FMUL);
            }
            else if($op.text.equals("/")) // sha de convertir a real tot, retorna real
            {
                if($tipus != lib_.REAL_)
                {
                    $tipus = lib_.REAL_;
                    $trad.add(bc_.ISTORE_0); // guardem t2
                    $trad.add(bc_.I2F); // pasem I -> R el t1
                    $trad.add(bc_.ILOAD_0); // recargem t2
                    $trad.add(bc_.I2F); // pasem I -> R el t2
                }
                $trad.add(bc_.FDIV);                
            }
            else if($op.text.equals("\\")) // sha de convertir a enter tot, retorna enter
            {
                if($tipus != lib_.ENTER_)
                {
                    $tipus = lib_.ENTER_;
                    $trad.add(bc_.ISTORE_0); // guardem t2
                    $trad.add(bc_.F2I); // pasem I -> R el t1
                    $trad.add(bc_.ILOAD_0); // recargem t2
                    $trad.add(bc_.F2I); // pasem I -> R el t2
                }
                $trad.add(bc_.IDIV);
            }
            else if($op.text.equals("%")) // retorna enter
            {
                if($tipus == lib_.ENTER_) 
                    $trad.add(bc_.IREM);
                else
                {
                    $trad.add(bc_.FREM);
                    $trad.add(bc_.F2I);
                    $tipus = lib_.ENTER_;
                }
            }
        })*
    ;

// --- expresions unaries
expUnari returns [Vector<Long> trad, char tipus, Long adreca]
@init{$adreca = -1L;}
    : op=(TK_OP_HASH | TK_OP_TILDE)? t=terme {
        if($op != null && $t.tipus != lib_.ENTER_ && $t.tipus != lib_.REAL_){ // Si no es ni enter ni real
            error = true;
            System.out.println("Error de unaris detectat a la linia " + $op.line);
            System.exit(-1);
        }else{
            $tipus = $t.tipus;
            $adreca = $t.adreca;
            $trad = $t.trad;
            //Aqui fer opperacions unaries TOP de la pila conte el valor
        }
    };

terme returns [Vector<Long> trad,char tipus, Long adreca]
@init{$trad = new Vector<Long>(10);
      $adreca = -1L;}
//@after{System.out.println($adreca);}
    : 
           id=TK_IDENT 
           { 
            if(!TS.existeix($id.text))
            {
                error = true;
                System.out.println("Error de terme detectat a la linia " + $id.line+
                "\nIDENT: "+$id.text+" no existeix."); 
                System.exit(-1);
            }
            Registre r = TS.obtenir($id.text);
            if(!r.teValor())
            {
                error=true;
                System.out.println("Error de terme detectat a la linia " + $id.line+"\n"+
                "IDENT: '"+$id.text+"' no te valor.");
                System.exit(-1); 
            }
            $tipus = r.getTipus();
            $adreca = r.getAdreca();
            if(r.getTipID() == lib_.CONST_)
            {
                $trad.add(bc_.LDC_W);
                $trad.add(bc_.nByte(r.getAdreca(),2));
                $trad.add(bc_.nByte(r.getAdreca(),1));

            }
            else if(r.getTipID() == lib_.VAR_)
            {
                if(r.getTipus()==lib_.ENTER_)
                {
                    $trad.add(bc_.ILOAD);
                    $trad.add(r.getAdreca());
                }
                else if(r.getTipus()==lib_.REAL_)
                {
                    $trad.add(bc_.FLOAD);
                    $trad.add(r.getAdreca());
                }
                else if(r.getTipus()==lib_.CAR_)
                {
                    $trad.add(bc_.CALOAD);
                    $trad.add(r.getAdreca());
                }
                else if(r.getTipus()==lib_.BOOL_)
                {
                    $trad.add(bc_.BALOAD);
                    $trad.add(r.getAdreca());
                }
            }
           }
            ((TK_OP_POINT TK_IDENT) 
          | (TK_OP_LKEY expressio TK_OP_RKEY) 
          | (TK_OP_LPAREN param_reals? TK_OP_RPAREN))?
      | TK_OP_LPAREN 
        t=expressio 
        { 
            $tipus = $t.tipus; 
            $adreca = $t.adreca;
            $trad = $t.trad;
        } 
        TK_OP_RPAREN
      | (ent=TK_ENTER 
        { 
            $tipus = lib_.ENTER_;
            $adreca = bc_.addConstant(String.valueOf(lib_.ENTER_),$ent.text);
        }
      | rea=TK_REAL  
        { 
            $tipus = lib_.REAL_; 
            $adreca = bc_.addConstant(String.valueOf(lib_.REAL_),$rea.text);
        }
      | boo=TK_BOOL  
        { 
            $tipus = lib_.BOOL_; 
            $adreca = bc_.addConstant(String.valueOf(lib_.BOOL_),$boo.text);
        }
      | car=TK_CAR   
        { 
            $tipus = lib_.CAR_; 
            $adreca = bc_.addConstant(String.valueOf(lib_.CAR_),$car.text.replaceAll("'",""));
        }
        ) 
        {
            $trad.add(bc_.LDC_W);
            $trad.add(bc_.nByte($adreca,2));
            $trad.add(bc_.nByte($adreca,1));
         }
      | op=TK_OP_NOT t=expressio
            {
                if($t.tipus != lib_.BOOL_){ // Si no és boolea
                    error = true;
                    System.out.println("Error de terme detectat a la linia " + $op.line);
                    System.exit(-1);
                }
                $tipus = $t.tipus;
                $adreca = $t.adreca;
                $trad = $t.trad;
            }
      ;
/////////////////////
// Regles lèxiques //
/////////////////////

//Separadors
TK_WS : (' '
      | '\t'
      | '\n'
      | '\r') -> skip
      ;

//Comentaris
TK_COMENTARI : ('//' ( ~ ( '\n' | '\r' ))*) -> skip ;

//Programa
TK_PC_PROGRAMA : 'programa' ;
TK_PC_IMPLEMENT : 'implementacio' ;
TK_PC_FPROGRAMA : 'fprograma' ;

//Definicio de tipus
TK_PC_TIPUS : 'tipus' ;
TK_PC_FTIPUS : 'ftipus' ;

//Variables
TK_PC_VAR : 'var' ;
TK_PC_FVAR : 'fvar' ;

//Constants
TK_PC_CONST : 'const' ;
TK_PC_FCONST : 'fconst' ;

//Tupla
TK_PC_TUPLA : 'tupla' ;
TK_PC_FTUPLA : 'ftupla' ;

//Vector
TK_PC_VECTOR : 'vector' ;
TK_PC_TO : 'fins_a' ;
TK_PC_FROM : 'de' ;

//Condicional
TK_PC_IF : 'si' ;
TK_PC_THEN : 'llavors' ;
TK_PC_ELSE : 'altrament' ;
TK_PC_FIF : 'fsi' ;

//Bucle - mentre
TK_PC_WHILE : 'bucle' ;
TK_PC_EXITIF : 'sortidasi' ;
TK_PC_FWHILE : 'fbucle' ;

//Bucle - per
TK_PC_FOR : 'per' ;
//TK_PC_TO : 'fins_a' ; // Mateix token per a (Vector)    
TK_PC_DO : 'fer' ;
TK_PC_FFOR : 'fper' ;

//Accio
TK_PC_ACCIO : 'accio' ;
TK_PC_FACCIO : 'faccio' ;

//Funcio
TK_PC_FUNCIO : 'funcio' ;
TK_PC_RETURNS : 'retorna' ;
TK_PC_FFUNCIO : 'ffuncio' ;

//Parametres formals
TK_PC_ENT : 'ent' ;
TK_PC_ENTSORT : 'entsort' ;

//Llegir i excriure
TK_PC_READ : 'llegir' ;
TK_PC_WRITE : 'escriure' ;
TK_PC_WRITELINE : 'escriureln' ;

//Tipus basics
TK_PC_ENTER : 'enter' ;
TK_PC_REAL : 'real' ;
TK_PC_CAR : 'car' ;
TK_PC_BOOL : 'boolea' ;

//Operadors
TK_OP_LPAREN : '(' ;
TK_OP_RPAREN : ')' ;

TK_OP_LKEY : '[' ;
TK_OP_RKEY : ']' ;

TK_OP_ASSIGN : ':=' ;

TK_OP_POINT : '.' ;
TK_OP_POINTS : ':' ;
TK_OP_SEMICOL : ';' ;
TK_OP_COMA : ',' ;

/// Relacionals ///
TK_OP_LESSOREQUAL : '<=' ;
TK_OP_MOREOREQUAL : '>=' ;
TK_OP_EQUAL : '==' ;
TK_OP_NOTEQUAL : '/=' ;
TK_OP_LESS : '<' ;
TK_OP_MORE : '>' ;

/// Aritmetics ///
TK_OP_PLUS : '+' ;
TK_OP_MINUS : '-' ;

TK_OP_STAR : '*' ;
TK_OP_BAR : '/' ;

TK_OP_CBAR : '\\' ;
TK_OP_PERCENT : '%' ;

TK_OP_TILDE : '~' ;
TK_OP_HASH : '#' ;

/// Logics ///
TK_OP_AND : '&' ;
TK_OP_OR : '|' ;
TK_OP_NOT : 'no' ;

//Dades
fragment
DIGIT : '1'..'9' ;

fragment
LLETRA : 'a' .. 'z'
       | 'A' .. 'Z'
       ;

TK_ENTER : DIGIT (DIGIT | '0')* | '0';

fragment
REAL_CIENT : (DIGIT (DIGIT | '0')* | '0') ('.' (DIGIT | '0')*)? ('e' | 'E') '-'?  DIGIT (DIGIT | '0')* ;

fragment
REAL : (DIGIT (DIGIT | '0')* | '0') '.' (DIGIT | '0')* ;

TK_REAL : REAL_CIENT | REAL ;

TK_CAR  : '\'' ('\u0000' .. '\u007F') '\'' ; // Del caracter NULL a DEL en ASCII

TK_BOOL : 'Cert' | 'Fals' ;

TK_STRING : '"' (~('\r' | '\n' | '"') | ('\\' ('\r' | '\n' | '"')))* '"' ;

TK_IDENT : LLETRA (LLETRA | DIGIT | '0' | '_' )* ;