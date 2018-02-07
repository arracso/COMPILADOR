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
         DefTipus defTip_ = new DefTipus();
         SymTable<Registre> TS = new SymTable<Registre>(1000);   
         boolean error = false; 
         
         static final Long nLocals = 1000L;
         static final Long maxStack = 10000L;
         
         int contVar=0;
         Bytecode bc_;

         //override method    
         public void notifyErrorListeners(Token offendingToken, String msg, RecognitionException e) {            
              super.notifyErrorListeners(offendingToken,msg,e);            
              error=true;              
         }
         
         public Vector<Long> escriure_ (Long adreca, Boolean saltLinia){
            Vector<Long> trad = new Vector<Long>(12);
            if(tok.tipus == defTip_.ENTER_)
            {
                // Imprimim un missatge per pantalla
                trad.add(bc_.LDC_W);
                trad.add(bc_.nByte(adreca,2));
                trad.add(bc_.nByte(adreca,1));
                trad.add(bc_.INVOKESTATIC);
                trad.add(bc_.nByte(bc_.mPutInt,2));
                trad.add(bc_.nByte(bc_.mPutInt,1));
            }
            if(saltlinia)
            {
                Long barN=bc_.addConstant("C","\n");
                trad.add(bc_.LDC_W);
                trad.add(bc_.nByte(barN,2));
                trad.add(bc_.nByte(barN,1));
                trad.add(bc_.INVOKESTATIC);
                trad.add(bc_.nByte(bc_.mPutChar,2));
                trad.add(bc_.nByte(bc_.mPutChar,1));
            }
            return trad
         }                              
}

///////////////////////////////////////
// Regles Sintactiques i Semantiques //
///////////////////////////////////////

inici 
@init
    {
        bc_ = new Bytecode("_compilat_");
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
            System.out.println(trad.size());
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
    @init{System.out.println("+ 'decl_constants'");}
    @after{System.out.println("- 'decl_constants'");}
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
				Long addr = bc_.addConstName($id1.text,String.valueOf($t.tipus),$l1.text);
                                TS.inserir($id1.text,new Registre($id1.text,$t.tipus, defTip_.CONST_,addr));
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
				Long addr = bc_.addConstName($id2.text,String.valueOf($t.tipus),$l2.text);
                                TS.inserir($id2.text,new Registre($id2.text,$t.tipus, defTip_.CONST_, addr));
                            }
                        }
                        )* TK_OP_SEMICOL
                    )+
                    TK_PC_FCONST
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
    :   ( TK_PC_ENTER   { $tipus = defTip_.ENTER_; }
        | TK_PC_CAR     { $tipus = defTip_.CAR_; }
        | TK_PC_REAL    { $tipus = defTip_.REAL_; }
        | TK_PC_BOOL    { $tipus = defTip_.BOOL_; }
        )
    ;

literal_tipus_basic returns [char tipus]    
    :   ( TK_ENTER  { $tipus = defTip_.ENTER_; }
        | TK_CAR    { $tipus = defTip_.CAR_; }
        | TK_REAL   { $tipus = defTip_.REAL_; }
        | TK_BOOL   { $tipus = defTip_.BOOL_; }
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
// -- Mirar que la variable no estigui a la TS, guardar la nova var a la TS 
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
                    TS.inserir($idList.get(i),new Registre($idList.get(i),$tip.tipus, defTip_.VAR_));
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
@init{$trad = new Vector<Long>(100);}
@after{}
          : ass=assignacio { $trad.addAll($ass.trad);}
          | cri=crida_accio { $trad.addAll($cri.trad);}
          | con=condicional { $trad.addAll($con.trad);}
          | buc=bucle { $trad.addAll($buc.trad);}
          | pe=per { $trad.addAll($pe.trad);}
          | esc=escriure { $trad.addAll($esc.trad);}
          | lleg=llegir { $trad.addAll($lleg.trad);}        
          ;
// [FER][DONE] assignacio (NO FET tupla i vector)
// -- Mirar si existeix la variable a la TS i = tipus a la expressio
assignacio returns [Vector<Long> trad] locals [char tipus]
    @init{ $trad = new Vector<Long>(0);
          System.out.println("+ 'assignacio'");}
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
                    else if(!(TS.obtenir($var.text)).modificable())
                    {
                        error=true;
                        System.out.println("Error assignacio a la linia " + $var.line+
                        "\nIDENT: '"+$var.text+"' no modificable.");
                        System.exit(-1);
                    }
                    else{
                         $tipus = TS.obtenir($var.text).getTipus();
                    }
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
                if($exp.tipus != $tipus){ // si veiem que no tenen el mateix tipus donem error
                    error=true;
                    System.out.println("Error assignacio a la linia " + $igual.line+
                    "\nASSIGNACIO DE TIPUS DIFERENTS.\n"+
                    $exp.text+": "+$exp.tipus+"\n"+$tipus);
                    System.exit(-1);
                }
            }
           ;

// --- crida accio
crida_accio  returns [Vector<Long> trad]
    @init{ $trad = new Vector<Long>(0);
          /*System.out.println("+ 'crida_accio'");*/}
    //@after{System.out.println("- 'crida_accio'");}
    :  TK_IDENT TK_OP_LPAREN param_reals? TK_OP_RPAREN TK_OP_SEMICOL 
            ;
param_reals : expressio (TK_OP_COMA expressio)* ;

// [FER] --- estructura condicional
condicional  returns [Vector<Long> trad]
    @init{ $trad = new Vector<Long>(0);
          /*System.out.println("+ 'condicional'");*/}
    //@after{System.out.println("- 'condicional'");}
    :   c=TK_PC_IF e=expressio TK_PC_THEN
                {
                    if($e.tipus != defTip_.BOOL_){
                        error=true;
                        System.out.println("Error condicional a la linia " + $c.line+ "\nL'EXPRESSIO NO ES DE TIPUS BOLEA.");
                        System.exit(-1);
                    }
                }
                    sentencia*
                ( TK_PC_ELSE
                    sentencia*)?
                TK_PC_FIF
            ;

// [FER] --- estructura mentre
bucle   returns [Vector<Long> trad]
    @init{ $trad = new Vector<Long>(0);
          /*System.out.println("+ 'bucle'");*/}
    //@after{System.out.println("- 'bucle'");}
    : TK_PC_WHILE
            sentencia*
        c=TK_PC_EXITIF e=expressio TK_OP_SEMICOL
        {
            if($e.tipus != defTip_.BOOL_){
                error=true;
                System.out.println("Error bucle mentre a la linia " + $c.line+ "\nL'EXPRESSIO NO ES DE TIPUS BOLEA.");
                System.exit(-1);
            }
        }
            sentencia*
        TK_PC_FWHILE
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
            else if($e1.tipus != defTip_.ENTER_ || $e1.tipus != $e2.tipus || $regIDEN.getTipus() != $e1.tipus){
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
@init{$saltlinia = false;
      System.out.println("+ 'escriure'");}
@after{System.out.println("- 'escriure'");}
    : (TK_PC_WRITE | TK_PC_WRITELINE {$saltlinia = true;}) TK_OP_LPAREN 
      (exp=expressio {$trad = escriure_($exp.adreca,$saltlinia);}
      | TK_STRING) (TK_OP_COMA (expressio | TK_STRING))* TK_OP_RPAREN TK_OP_SEMICOL ;

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
         };


// Estructrura expressions
// --- expresions booleanes
expressio returns [char tipus, Long adreca]
    @init{ 
          System.out.println("+ 'expressio'");
          $adreca = -1L;
         }
    @after{System.out.println("- 'expressio'");}
    : t1=exprRelacionals 
      { 
        $tipus = $t1.tipus; 
        $adreca = $t1.adreca;
      }
        ( op=(TK_OP_AND | TK_OP_OR) t2=exprRelacionals {
            if($t1.tipus != defTip_.BOOL_ || $t2.tipus != defTip_.BOOL_){
                error=true;
                System.out.println("Error de booleans detectat a la linia " + $op.line);
                System.exit(-1);
            }
        })*
    ;

// --- expresions relacionals
exprRelacionals returns [char tipus, Long adreca]
@init{$adreca = -1L;}
    : t1=exprArit 
      {
        $tipus = $t1.tipus; 
        $adreca = $t1.adreca;
      }
        ( op=(TK_OP_LESSOREQUAL | TK_OP_MOREOREQUAL | TK_OP_EQUAL | TK_OP_NOTEQUAL | TK_OP_LESS | TK_OP_MORE) t2=exprArit {
            if(($t1.tipus == defTip_.ENTER_ || $t1.tipus == defTip_.REAL_) && ($t2.tipus == defTip_.ENTER_ || $t2.tipus == defTip_.REAL_)){
                $tipus = defTip_.BOOL_;
            }else if($t1.tipus == $t2.tipus && ($op.text == "==" || $op.text == "/=")){
                $tipus = defTip_.BOOL_;
            }else{
                error=true;
                System.out.println("Error de relacionals detectat a la linia " + $op.line+"\n"+
                $t1.text+": "+$t1.tipus+"\n"+$t2.text+": "+$t2.tipus);
                System.exit(-1);
            }
        })* 
    ;

// --- expresions suma resta
exprArit returns [char tipus, Long adreca]
@init{$adreca = -1L;}
    : t1=exprArit2 
      { 
        $tipus = $t1.tipus;
        $adreca = $t1.adreca;
      }
        ( op=(TK_OP_PLUS | TK_OP_MINUS) t2=exprArit2 {
            if(($t1.tipus != defTip_.ENTER_ && $t1.tipus != defTip_.REAL_) || ($t2.tipus != defTip_.ENTER_ && $t2.tipus != defTip_.REAL_)){ // Si no son ni enters ni reals
                error=true;
                System.out.println("Error de aritmetic detectat a la linia " + $op.line+
                "\n"+$t1.text+": "+$t1.tipus+
                "\n"+$t2.text+": "+$t2.tipus);
                System.exit(-1);
            }else if ($t2.tipus == defTip_.REAL_){
                $tipus = defTip_.REAL_;
            }
        })*
    ;

// --- expresions producte divisio
exprArit2 returns [char tipus, Long adreca]
@init{$adreca = -1L;}
    : t1=expUnari  
      { 
        $tipus = $t1.tipus; 
        $adreca = $t1.adreca;
      }
        ( op=(TK_OP_STAR | TK_OP_BAR | TK_OP_CBAR | TK_OP_PERCENT) t2=expUnari {
            if(($t1.tipus != defTip_.ENTER_ && $t1.tipus != defTip_.REAL_) || ($t2.tipus != defTip_.ENTER_ && $t2.tipus != defTip_.REAL_)){ // Si no son ni enters ni reals
                error=true;
                System.out.println("Error de aritmetic_2 detectat a la linia " + $op.line);
                System.exit(-1);
            }else if ($t2.tipus == defTip_.REAL_){
                $tipus = defTip_.REAL_;
            }
        })*
    ;

// --- expresions unaries
expUnari returns [char tipus, Long adreca]
@init{$adreca = -1L;}
    : op=(TK_OP_HASH | TK_OP_TILDE)? t=terme {
        if($op != null && $t.tipus != defTip_.ENTER_ && $t.tipus != defTip_.REAL_){ // Si no es ni enter ni real
            error = true;
            System.out.println("Error de unaris detectat a la linia " + $op.line);
            System.exit(-1);
        }else{
            $tipus = $t.tipus;
            $adreca = $t.adreca;
        }
    };

terme returns [char tipus, Long adreca]
@init{$adreca = -1L;}
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
            else
            {
                $tipus = TS.obtenir($id.text).getTipus();
            }
           }
            ((TK_OP_POINT TK_IDENT) 
          | (TK_OP_LKEY expressio TK_OP_RKEY) 
          | (TK_OP_LPAREN param_reals? TK_OP_RPAREN))?
      | TK_OP_LPAREN t=expressio { $tipus = $t.tipus; } TK_OP_RPAREN
      | ent=TK_ENTER 
        { 
            $tipus = defTip_.ENTER_;
            $adreca = bc_.addConstant("I",$ent.text);
        }
      | rea=TK_REAL  
        { 
            $tipus = defTip_.REAL_; 
            $adreca = bc_.addConstant("F",$rea.text);
        }
      | boo=TK_BOOL  
        { 
            $tipus = defTip_.BOOL_; 
            $adreca = bc_.addConstant("Z",$boo.text);
        }
      | ca=TK_CAR   
        { 
            $tipus = defTip_.CAR_; 
            $adreca = bc_.addConstant("C",$ca.text);
        }
      | op=TK_OP_NOT t=expressio
            {
                $tipus = $t.tipus;
                if($t.tipus != defTip_.BOOL_){ // Si no és boolea
                    error = true;
                    System.out.println("Error de terme detectat a la linia " + $op.line);
                    System.exit(-1);
                }
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

TK_BOOL : 'cert' | 'fals' ;

TK_STRING : '"' ('\u0000' .. '\u007F')* '"' ; 

TK_IDENT : LLETRA (LLETRA | DIGIT | '0' | '_' )* ;