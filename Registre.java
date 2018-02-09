// Josep Suy abril 2007


public class Registre  {

	String lexema_;
	char tipus_;
	Long adreca_;
    char tipID_; // per saber si el lexema_ es un constant 'c', variable 'v', funcio 'f', accio 'a'
    Lib lib_;
    Boolean valor_=false; // per saber si te un valor assignat

public Registre() {
	lexema_="";
	tipus_='I';
	adreca_=-1L;
	}


public Registre(String l) {
	lexema_=l;
	tipus_='I';
	adreca_=-1L;
	}
public Registre(String l, char t) {
	lexema_=l;
	tipus_=t;
	adreca_=-1L;
	}
public Registre(String l, char t, Long a) {
	lexema_=l;
	tipus_=t;
	adreca_=a;
	}
public Registre(String l, char t, char tid) {
	lexema_=l;
	tipus_=t;
	adreca_=-1L;
    tipID_=tid;
	}
public Registre(String l, char t, char tid, Long a) {
	lexema_=l;
	tipus_=t;
	adreca_=a;
    tipID_=tid;
    if(tipID_ != lib_.VAR_) {valor_ = true;}
	}

public String getLexema() {
	return (lexema_);
	}
public char getTipus() {
	return (tipus_);
	}
public Long getAdreca() {
	return (adreca_);
	}
public char getTipID() {
	return (tipID_);
	}
// retorna cert si es una variable, fals alstrament
public boolean modificable() {
	return tipID_==lib_.VAR_;
	}
// retorna cert si aquest registre te assignat un valor, fals altrament
public boolean teValor(){
    return valor_;
}

public void putLexema(String l) {
	lexema_=l;
	}
public void putTipus(char t) {
	tipus_=t;
	}
public void putAdreca(Long a) {
	adreca_=a;
	}
// assinga a valor_ = true, voldra dir que aquest registre te un vaolr assignat
public void putValor(){
    valor_ = true;
}

}
