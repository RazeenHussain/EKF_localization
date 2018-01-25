% Implements the evolution model of the system. Here, this model is simply the equations of odometry.

function Xnew = EvolutionModel( Xold , U )

% X=(x,y,theta,rR,rL)  U=(qRdot,qLdot)

global trackGauge period ;

v = (1/2)*( Xold(4)*U(1) + Xold(5)*U(2) )             ;
w = Xold(4)/trackGauge*U(1) - Xold(5)/trackGauge*U(2) ;

D = [ v*period ;
      w*period ] ;
    
Xnew = [ Xold(1)+D(1)*cos(Xold(3)) ;
         Xold(2)+D(1)*sin(Xold(3)) ;
                      Xold(3)+D(2) ;
                           Xold(4) ;
                           Xold(5) ] ;
          
return          
