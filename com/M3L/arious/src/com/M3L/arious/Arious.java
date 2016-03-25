package com.M3L.arious;
import android.app.*;
import android.os.*;
import android.widget.*;
import android.view.*;
import android.view.View.*;

public class Arious extends Activity{
  Boolean __var$1 = true;
  int __var$2 = 0;
  float __var$3 = 0;
  float __var$4 = 0;
  Boolean __var$5 = false;
  float __var$6 = 0;
  @Override
  public void onCreate(android.os.Bundle saved){
    super.onCreate(saved);
    this.setContentView(R.layout.main);
    final EditText __var$7 = (EditText)this.findViewById(R.id.__btn1);
    __var$7.getText().toString();
    final Button __var$8 = (Button)this.findViewById(R.id.__btn2);
    __var$8.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        if(__var$1)  {
            __var$7.getText().clear();
            __var$7.getText().append("7");
            __var$1=false;
          }else  {
            __var$7.getText().append("7");
          };
        __var$5=false;
      }
    }));
    final Button __var$9 = (Button)this.findViewById(R.id.__btn3);
    __var$9.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        if(__var$1)  {
            __var$7.getText().clear();
            __var$7.getText().append("8");
            __var$1=false;
          }else  {
            __var$7.getText().append("8");
          };
        __var$5=false;
      }
    }));
    final Button __var$10 = (Button)this.findViewById(R.id.__btn4);
    __var$10.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        if(__var$1)  {
            __var$7.getText().clear();
            __var$7.getText().append("9");
            __var$1=false;
          }else  {
            __var$7.getText().append("9");
          };
        __var$5=false;
      }
    }));
    final Button __var$11 = (Button)this.findViewById(R.id.__btn5);
    __var$11.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        __var$2=0;
        __var$3=Float.parseFloat(__var$7.getText().toString());
        __var$1=true;
        __var$5=false;
      }
    }));
    final Button __var$12 = (Button)this.findViewById(R.id.__btn6);
    __var$12.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        if(__var$1)  {
            __var$7.getText().clear();
            __var$7.getText().append("4");
            __var$1=false;
          }else  {
            __var$7.getText().append("4");
          };
        __var$5=false;
      }
    }));
    final Button __var$13 = (Button)this.findViewById(R.id.__btn7);
    __var$13.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        if(__var$1)  {
            __var$7.getText().clear();
            __var$7.getText().append("5");
            __var$1=false;
          }else  {
            __var$7.getText().append("5");
          };
        __var$5=false;
      }
    }));
    final Button __var$14 = (Button)this.findViewById(R.id.__btn8);
    __var$14.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        if(__var$1)  {
            __var$7.getText().clear();
            __var$7.getText().append("6");
            __var$1=false;
          }else  {
            __var$7.getText().append("6");
          };
        __var$5=false;
      }
    }));
    final Button __var$15 = (Button)this.findViewById(R.id.__btn9);
    __var$15.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        __var$2=1;
        __var$3=Float.parseFloat(__var$7.getText().toString());
        __var$1=true;
        __var$5=false;
      }
    }));
    final Button __var$16 = (Button)this.findViewById(R.id.__btn10);
    __var$16.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        if(__var$1)  {
            __var$7.getText().clear();
            __var$7.getText().append("1");
            __var$1=false;
          }else  {
            __var$7.getText().append("1");
          };
        __var$5=false;
      }
    }));
    final Button __var$17 = (Button)this.findViewById(R.id.__btn11);
    __var$17.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        if(__var$1)  {
            __var$7.getText().clear();
            __var$7.getText().append("2");
            __var$1=false;
          }else  {
            __var$7.getText().append("2");
          };
        __var$5=false;
      }
    }));
    final Button __var$18 = (Button)this.findViewById(R.id.__btn12);
    __var$18.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        if(__var$1)  {
            __var$7.getText().clear();
            __var$7.getText().append("3");
            __var$1=false;
          }else  {
            __var$7.getText().append("3");
          };
        __var$5=false;
      }
    }));
    final Button __var$19 = (Button)this.findViewById(R.id.__btn13);
    __var$19.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        __var$2=2;
        __var$3=Float.parseFloat(__var$7.getText().toString());
        __var$1=true;
        __var$5=false;
      }
    }));
    final Button __var$20 = (Button)this.findViewById(R.id.__btn14);
    __var$20.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        if(__var$1)  {
            __var$7.getText().clear();
            __var$7.getText().append("0");
            __var$1=false;
          }else  {
            __var$7.getText().append("0");
          };
        __var$5=false;
      }
    }));
    final Button __var$21 = (Button)this.findViewById(R.id.__btn15);
    __var$21.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        if(__var$1)  {
            __var$7.getText().clear();
            __var$7.getText().append(".");
            __var$1=false;
          }else  {
            __var$7.getText().append(".");
          };
        __var$5=false;
      }
    }));
    final Button __var$22 = (Button)this.findViewById(R.id.__btn16);
    __var$22.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        if(!__var$5)  {
            __var$4=Float.parseFloat(__var$7.getText().toString());
          };
        if(__var$2==0)  {
            __var$3=__var$3+__var$4;
            __var$7.getText().clear();
            __var$7.getText().append(Float.toString(__var$3));
          };
        if(__var$2==1)  {
            __var$3=__var$3-__var$4;
            __var$7.getText().clear();
            __var$7.getText().append(Float.toString(__var$3));
          };
        if(__var$2==2)  {
            __var$3=__var$3*__var$4;
            __var$7.getText().clear();
            __var$7.getText().append(Float.toString(__var$3));
          };
        if(__var$2==3)  {
            __var$3=__var$3/__var$4;
            __var$7.getText().clear();
            __var$7.getText().append(Float.toString(__var$3));
          };
        __var$1=true;
        __var$5=true;
      }
    }));
    final Button __var$23 = (Button)this.findViewById(R.id.__btn17);
    __var$23.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        __var$2=3;
        __var$3=Float.parseFloat(__var$7.getText().toString());
        __var$1=true;
        __var$5=false;
      }
    }));
    final Button __var$24 = (Button)this.findViewById(R.id.__btn18);
    __var$24.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        __var$7.getText().clear();
        __var$7.getText().append("");
        __var$1=true;
        __var$5=false;
        __var$2=0;
      }
    }));
    final Button __var$25 = (Button)this.findViewById(R.id.__btn19);
    __var$25.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        __var$7.getText().clear();
        __var$7.getText().append("");
        __var$1=true;
      }
    }));
    final Button __var$26 = (Button)this.findViewById(R.id.__btn20);
    __var$26.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        __var$6=__var$6+Float.parseFloat(__var$7.getText().toString());
      }
    }));
    final Button __var$27 = (Button)this.findViewById(R.id.__btn21);
    __var$27.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        __var$6=__var$6-Float.parseFloat(__var$7.getText().toString());
      }
    }));
    final Button __var$28 = (Button)this.findViewById(R.id.__btn22);
    __var$28.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        __var$7.getText().clear();
        __var$7.getText().append(Float.toString(__var$6));
      }
    }));
    final Button __var$29 = (Button)this.findViewById(R.id.__btn23);
    __var$29.setOnClickListener((new OnClickListener(){  
      public void onClick(View w){
        __var$6=0;
      }
    }));
  };
};
