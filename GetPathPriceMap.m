function  [BestPathPrice]=GetPathPriceMap() 
%{
Description:
Find all cheapest paths on the image, leading from pixel A to any pixel in the image.
Or
Find the cheapest legal path on the image between  points A and B and return this path and its cost.   
Input  Global: 
Icol: Color image of the vessel containing the material.
I: Grayscale image of the vessel containing the material.
Iedge: Canny edge image of the vessel containing the material.
Hight, Width:  Height and width of of the image examined (I).

Ax,Ay, Bx,By: Coordinates of endpoints of the path that is explored in this step. 
This coordinates refer to the pixels in the image in which the path start (Ax, Ay) and end (Bx,By).
LegalPath: Binary image in the size of the image examined (I) in which all legal pixels in which the path currently explored can pass marked 1 (green region in Figure 4) and the rest marked 0. 

Output	
PathMap: Matrix in size of the image examined (I) in which every cell contains the cost of the path from start point A to this cell
BackX, BackY: Matrix in size of the image examined (I) in which every cell contains coordinates of the previous pixel in the path from the start point A to this cell. 
This matrix allows you to track all paths leading from A in the image.
%}
%if (nargin<1) GradeChangeDirection1=0;end; %Determine wether the price will consider the gradient sign relative to curve 0(no) +/-1 yes
global Ax Ay Bx By LegalPath PathMap BackX BackY Y Yb X Xb  Hight Width VerticalMoves Kvert %Gradient2BorderDirection
PrvY1=zeros(1000);%Array containing the previus(Prvx/y) location and next location (NxtX/Y), for all possible paths to  be explore this round
NxtY1=zeros(1000);
N1=0;% Number of possible paths/propogation steps to explore this round 
PrvY2=zeros(1000);%Array containing the previus(Prvx/y) location and next(NxtX/Y) location for all possible steps to explore in next round 
NxtY2=zeros(1000); 
N2=0;% Number of propogation steps for next round 
VerNxtY=zeros(1000); %Array containing the previus(Prvx/y) location and next location (NxtX/Y), for all vertical propogation steps (x,y)->(x,y+/-1) to explore this/next round 
VerPrvY=zeros(1000);
NV=0; %number of vertical moves for this round
NV2=0;% number of vertical moves for next round
PathMap=ones(Hight, Width)*100000;%Matrix in size of I. Each cell give the Prices of path from point A to the current pixel in the image
BackX=zeros(Hight, Width);% Matrix with the coordinate of the (previous pixel in path leading from A to this Pixel)
BackY=zeros(Hight, Width);

%===========================Set intial Step==================================================================================================
N1=1; PrvY1(1)=Ay; NxtY1(1)=Ay; % set initial step leading from point A
%==============Main loop Calculate Minimal Path==============================================================================================================================
for X=Ax:1:Bx% Scan the path price from A to every point up to B. This is done column by column (fx isnt realy used)
    Xb=X-1;% The prvious pixel for pixel located in X gor none vertical propogation previous X location is one X-1
    for f=1:N1% Scan all moves for this round
        Y=NxtY1(f);% to make reading simplier Write the Next coordinates of this move as X and Y (not really necessary and make code slower, when writing in opencv use define)
        Yb=PrvY1(f);       
        %--------------------------------------------Find next moves from location X,Y to X+1 (if point havent been explored before)--------------------------------------------------------
        if  PathMap(Y,X)==100000 %if this point have not been explored. Find All paths leading from this point and add them to the list of step to explore next move
            for f1=-1:1:1
               if  Y+f1>1 && Y+f1<Hight && X+1<=Width && LegalPath(Y+f1,X+1)==1 % If the point (X+1,Y+f1) leading from is legal add it to the next moves list
                   N2=N2+1;%Increase number move to explore in next cycle          
                   PrvY2(N2)=Y;
                   NxtY2(N2)=Y+f1;
               end;
            end;
            %................Find Next vertical moves for path propogation. From (x,y) to (x,y+/-1)...................................................................
                for f1=-1:2:1
                   if  Y+f1>1 && Y+f1<Hight &&  LegalPath(Y+f1,X)==1 %if above/below point are legal position add them to the vertical move list
                      NV=NV+1;% Add move to list 
                      VerNxtY(NV)=Y+f1; %(Previous and Next location of each move NV is the number of vertical moves)
                      VerPrvY(NV)=Y;
                   end
                end
        end;
        %----------------------------------Calculate path price with this move (Xb,Yb)->(X,Y) ------------------------------------------------------------------------
        if (X==Ax && Y==Ay)  PathMap(Ay,Ax)=0; %In path starting point (A)  price is always zero
        else % if not starting point calculate price
          Price=PointPrice()+PathMap(Yb,Xb); %PRice of  total path including this move.  Price(A->[X,Y])=(A->[Xb,Yb])+ price( [Xb,Yb]->[X,Y])
          if Price<PathMap( Y, X)%If price for point X,Y cheaper from previous Price  appear in PathMap write it instead of previous price
            PathMap(Y,X)=Price;%Write new price
            BackX(Y,X)=Xb;%X-1; %Update location of previews point in the path according to this path
            BackY(Y,X)=Yb;
          end;
        end;
    end;

 %=================Vertical propogation of path in line X (X,Y)->(X,Y+/-1)===========================================================================================
    Xb=X;%For vertical propogation previous location is the same X 
   Nmov=VerticalMoves;% Maximal Number of sequential vertical propogation steps left for this column
   while (Nmov>0)% &&  NV>0) % as long as there move (NV) and max number of vertical moves have not been excideed
 %----------------------------------Scan all NV vertical moves------------------------------------------------------------------------------------------------------
      for f=1:NV 
         Y=VerNxtY(f); %Next place
         Yb=VerPrvY(f);    %Previous place
  %--------------------------------Find next moves from location X,Y to X+1 (if point havent been explored before)--------------------------------------------------------        
         if  PathMap(Y,X)==10000 %if this point have not been exploredd. All paths leading from this point and add them to the list of step to explore next move
            for f1=-1:1:1
               if  Y+f1>1 && Y+f1<Hight && X+1<=Width && LegalPath(Y+f1,X+1)==1 % if the point leading from X,Y is legal add it to the next moves list
                   N2=N2+1;%increase move to explore in next cycle
                   PrvY2(N2)=Y;
                   NxtY2(N2)=Y+f1;
               end;
            end;
         end;
%,,,,,,,,,,,,,,,,Calculate price for the path containing the current move----------------------------------------------------         
           Price=PointPrice()*Kvert+PathMap(Yb,X);%Price of this move + price of previus path (Kvert is extra price for discouraging vertical propogation)
%,,,,,,,,,,,,,,if price lower from previous price write the path and find next vertical moves..................................           
           if Price<PathMap(Y,X)%if price cheaper from previous Price to X,Y write it instead of previous path/price
              PathMap(Y,X)=Price;%Write new price
              BackX(Y,X)=Xb;%X
              BackY(Y,X)=Yb;
 %................Find Next vertical move for path propogation from X,Y to X,Y+1/-1...................................................................
                dy=Y-Yb;
                   if  Y+dy>1 && Y+dy<Hight &&  LegalPath(Y+dy,X)==1 %If above/below point are legal add them to the vertical move list
                      NV2=NV2+1;
                      VerNxtY(NV2)=Y+dy; % of vertical moves for current line only Y is needed since the X is the X of the line (Previous and Next location of each move NV is the number of vertical moves)
                      VerPrvY(NV2)=Y;
                   end  
%---------------------------------------------------------------------------------------------------------------------
           end;
      end
      NV=NV2;%update vertical moves
      NV2=0;
      Nmov=Nmov-1;% Reduce number of vertical moves left for this round/column
  end
%=================================================================================================================================
 %-------------------------------update  List of moves, copy list of move for next cycle to current cycle-----------------------------------------------------------------------------------------------       
    N1=N2; %
    N2=0;
    NV=0;
    PrvY1=PrvY2;
    NxtY1=NxtY2;
%-----------------------------------------------------------------------------------------------------------------------------
end;
BestPathPrice=PathMap(By,Bx);%the minimal path price from point A to B
%==========================================================================================================================
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PointPrice]=PointPrice()
PointPrice=PointPrice6();%*HighPriceZone(Y,X);%+HighPriceZone(Y,X)*0.2;%*0.4;%*sqrt(abs(Y-Yb)+abs(X-Xb));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 function [PointPrice]=PointPrice1()
 %Calculate Price according to wether the path propogate along edge line,
 %Iedge Edge image
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
 global Iedge Y X Xb Yb HighPriceZone
     if     (Iedge(Y,X)==0   &&  Iedge(Yb,Xb)==1)  PointPrice=1;  %propogation from edge to no edge worst possibility
     elseif (Iedge(Y,X)==0   &&  Iedge(Yb,Xb)==0)  PointPrice=0.5;   
     elseif (Iedge(Y,X)==1   &&  Iedge(Yb,Xb)==0)  PointPrice=0.25; 
     elseif (Iedge(Y,X)==1   &&  Iedge(Yb,Xb)==1)  PointPrice=0.1; 
     end; %Propogation allonh edge is best cheapest approach
   PointPrice=PointPrice*HighPriceZone(Y,X);% %Add extra price if in the high price zone
 end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function [PointPrice]=PointPrice2()
 %Calculate Price as the intensity change normal to curve (ignore gradient sign in price)
 %I intensity image
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
   global I Y X Xb Yb HighPriceZone
     Dy=Y-Yb;
     Dx=X-Xb;
     PointPrice=1-abs(I(Y-Dx,X+Dy)-I(Y+Dx,X-Dy ))/255;
     PointPrice=PointPrice*HighPriceZone(Y,X); %Add extra price if in the high price zone
  end
  
 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 function [PointPrice]=PointPrice3()
 %Calculate Price as the relative intenisty change normal to curve (Ignore gradient sign in price calculation)
 %scalar mutipication of  the normalize gradient normal and the path line at this point using the intensity image (yet another mode)
 %I intensity image
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
    global I Y X Xb Yb HighPriceZone
     Dy=Y-Yb;
     Dx=X-Xb; 
     PointPrice=1-abs(I(Y-Dx,X+Dy)-I(Y+Dx,X-Dy ))/max([I(Y-Dx,X+Dy) I(Y+Dx,X-Dy ) 1]);
     PointPrice=PointPrice*HighPriceZone(Y,X); %Add extra price if in the high price zone
 end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
   function [PointPrice]=PointPrice4()
 %Calculate Price as the intensity change normal to curve (ignore gradient sign in price)
 %I intensity image
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
   global I Y X Xb Yb HighPriceZone
     Dy=Y-Yb;
     Dx=X-Xb;
     PointPrice=1-abs(I(Y,X)-I(Y+Dx,X-Dy ))/255;
     PointPrice=PointPrice*HighPriceZone(Y,X); %Add extra price if in the high price zone
  end
 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 function [PointPrice]=PointPrice5()
 %Calculate Price as the relative intenisty change normal to curve (Ignore gradient sign in price calculation)
 %scalar mutipication of  the normalize gradient normal and the path line at this point using the intensity image (yet another mode)
 %I intensity image
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
 global I Y X Xb Yb HighPriceZone
     Dy=Y-Yb;
     Dx=X-Xb; 
     PointPrice=1-abs(I(Y,X)-I(Y+Dx,X-Dy ))/max([I(Y,X) I(Y+Dx,X-Dy ) 1]);
     PointPrice=PointPrice*HighPriceZone(Y,X); %Add extra price if in the high price zone
end
 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 function [PointPrice]=PointPrice6()
%Calculate Price As difference between edge density  of the pixel and the pixel on both side of the curve (normal to curve) 
   global  Iedge Y X Xb Yb  HighPriceZone 
   Dy=Y-Yb;
   Dx=X-Xb;
   PointPrice=1.3-Iedge(Y,X)+(Iedge(Y+Dx,X-Dy)+Iedge(Y-Dx,X+Dy))/2;
   PointPrice=(PointPrice)*HighPriceZone(Y,X); %Add extra price if in the high price zone
 end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PointPrice]=PointPrice7()
 %Calculate Price as the edge density size in the point
 %I intensity image
 %X,Y location of current point
     global Iedge Y X  HighPriceZone
    PointPrice=1.3-Iedge(Y,X);
    PointPrice=PointPrice*HighPriceZone(Y,X); %Add extra price if in the high price zone
 end   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PointPrice]=PointPrice8()
%Calculate Price As difference between edge density of the pixel and the pixel
%above  it (relative intensity change)
   global  Iedge Y X Xb Yb  HighPriceZone
   Dy=Y-Yb;
   Dx=X-Xb;
   PointPrice=1.3-(Iedge(Y,X)-Iedge(Y-Dx,X+Dy));
   PointPrice=PointPrice()*HighPriceZone(Y,X);

end


%{
Unused
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function [PointPrice]=PointPrice4Sign()
 %Calculate Price as the intensity change normal to curve (use gradient sign in price calculation)
 %I intensity image
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
   global I Y X Xb Yb Gradient2BorderDirection HighPriceZone
     Dy=Y-Yb;
     Dx=X-Xb;
             PointPrice=1-(I(Y,X)-I(Y+Dx,X-Dy ))/255*Gradient2BorderDirection;
  
         PointPrice=PointPrice*HighPriceZone(Y,X); %Add extra price if in the high price zone

  end
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 function [PointPrice]=PointPrice3Sign() 
 %Calculate Price as the relative intenisty change normal to curve (use gradient sign in price calculation)
 %Rscalar mutipication of  the normalize gradient normal and the path line at this point using the intensity image (yet another mode)
 %I intensity image
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
    global I Y X Xb Yb Gradient2BorderDirection HighPriceZone
     Dy=Y-Yb;
     Dx=X-Xb;
     PointPrice=1-(I(Y-Dx,X+Dy)-I(Y+Dx,X-Dy ))/max([I(Y-Dx,X+Dy) I(Y+Dx,X-Dy ) 1])*Gradient2BorderDirection;
     PointPrice=PointPrice*HighPriceZone(Y,X); %Add extra price if in the high price zone

 end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 function [PointPrice]=PointPrice5Sign() 
 %Calculate Price as the relative intenisty change normal to curve (use gradient sign in price calculation)
 %Rscalar mutipication of  the normalize gradient normal and the path line at this point using the intensity image (yet another mode)
 %I intensity image
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
    global I Y X Xb Yb Gradient2BorderDirection HighPriceZone
     Dy=Y-Yb;
     Dx=X-Xb;
     PointPrice=1-(I(Y,X)-I(Y+Dx,X-Dy ))/max([I(Y,X) I(Y+Dx,X-Dy ) 1])*Gradient2BorderDirection;
     PointPrice=PointPrice*HighPriceZone(Y,X); %Add extra price if in the high price zone

 end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function [PointPrice]=PointPrice2Sign()
 %Calculate Price as the intensity change normal to curve (use gradient sign in price calculation)
 %I intensity image
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
   global I Y X Xb Yb Gradient2BorderDirection HighPriceZone
     Dy=Y-Yb;
     Dx=X-Xb;
             PointPrice=1-(I(Y-Dx,X+Dy)-I(Y+Dx,X-Dy ))/255*Gradient2BorderDirection;
  
         PointPrice=PointPrice*HighPriceZone(Y,X); %Add extra price if in the high price zone

  end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PointPrice]=PointPrice6()
    %Intensity Change
%Calculate Price As difference between intensity of the pixel and the pixel
%above  it (relative intensity change)
   global  I X Y  
   PointPrice=(I(Y,X)-I(Y-1,X))/255;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PointPrice]=PointPrice6b()
    %Intensity Change
%Calculate Price As difference between intensity of the pixel and the pixel
%above  it (relative intensity change)
   global  I X Y  Gradient2BorderDirection HighPriceZone
 
   if Gradient2BorderDirection==0  
         PointPrice=1-abs((I(Y,X)-I(Y-1,X))/255); %/255 % score is independent of gradient sign relative to border
   else
       PointPrice=1-((I(Y,X)-I(Y-1,X))/255)*Gradient2BorderDirection; % score is dependent of gradient sign relative to border
   end;
    PointPrice=PointPrice*HighPriceZone(Y,X); %If the high price zone is calculated within the function

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PointPrice]=PointPrice7()
    %Intensity change
%Calculate Price As difference between intensity above and below pixel
    global  I X Y     
    PointPrice=(I(Y+1,X)-I(Y-1,X))/255;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PointPrice]=PointPrice7b()
    %Intensity change
%Calculate Price As difference between intensity above and below pixel
 global  I X Y  Gradient2BorderDirection HighPriceZone
   if Gradient2BorderDirection==0  
       PointPrice=1-abs((I(Y+1,X)-I(Y-1,X))/255); % score is independent of gradient sign relative to border
   else
       PointPrice=1-((I(Y+1,X)-I(Y-1,X))/255)*Gradient2BorderDirection; % score is dependent of gradient sign relative to border
   end;
      PointPrice=PointPrice*HighPriceZone(Y,X); %If the high price zone is calculated within the function

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PointPrice]=PointPrice8()
%Relative intensity change    
%Calculate Price As difference between intensity of the pixel and the pixel above pixel, divide dy the average untensity (relative intensity change)
 global  I X Y   %HighPriceZone    
     PointPrice=(I(Y+1,X)-I(Y,X))/max([I(Y+1,X) I(Y,X) 1]);%*HighPriceZone(Y,X); %If the high price zone is calculated within the function
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PointPrice]=PointPrice8b()
%Relative intensity change above and on curve   
%Calculate Price As difference between intensity of the pixel and the pixel above pixel, divide dy the average untensity (relative intensity change)
 global  I X Y Gradient2BorderDirection HighPriceZone   

   if Gradient2BorderDirection==0  
      PointPrice=1-abs(I(Y+1,X)-I(Y,X))/max([I(Y+1,X) I(Y,X) 1]); % score is independent of gradient sign relative to border
   else
       PointPrice=1-(I(Y+1,X)-I(Y,X))/max([I(Y+1,X) I(Y,X) 1])*Gradient2BorderDirection; % score is dependent of gradient sign relative to border
   end;
   PointPrice=PointPrice*HighPriceZone(Y,X); %If the high price zone is calculated within the function
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PointPrice]=PointPrice9()
%Calculate Price As difference between intensity of the above and below pixel, divide vy the average untensity (relative intensity change)
   global I Y X %HighPriceZone 
   
         PointPrice=(I(Y+1,X)-I(Y-1,X))/max([I(Y+1,X) I(Y-1,X) 1]);%*HighPriceZone(Y,X); %If the high price zone is calculated within the function
     
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PointPrice]=PointPrice9b()
%Calculate Price As difference between intensity of the above and below pixel, divide vy the average untensity (relative intensity change)
 global  I X Y Gradient2BorderDirection HighPriceZone    

   if Gradient2BorderDirection==0  
      PointPrice=1-abs(I(Y+1,X)-I(Y-1,X))/max([I(Y+1,X) I(Y-1,X) 1]); % score is independent of gradient sign relative to border
   else
       PointPrice=1-(I(Y+1,X)-I(Y-1,X))/max([I(Y+1,X) I(Y-1,X) 1])*Gradient2BorderDirection; % score is dependent of gradient sign relative to border
   end;
 PointPrice=PointPrice*HighPriceZone(Y,X); %If the high price zone is calculated within the function
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 function [PointPrice]=PointPrice10()
 %Calculate Price as the scalar mutipication of  the gradient normal and the path line at this point
 %Igrd Gradient map of the image each cell is 2d Vectot
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
    global IgrdX IgrdY Y X Xb Yb
    Dy=Y-Yb;
    Dx=X-Xb;
        PointPrice=(IgrdY(Y,X)*Dx-IgrdX(Y,X,1)*Dy)/sqrt(Dy+Dx)/255;% multiple the gradient by curve normal
 end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 function [PointPrice]=PointPrice10b()
 %Calculate Price as the scalar mutipication of  the gradient normal and the path line at this point
 %Igrd Gradient map of the image each cell is 2d Vectot
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
    global IgrdX IgrdY Y X Xb Yb Gradient2BorderDirection
    Dy=Y-Yb;
    Dx=X-Xb;
     if Gradient2BorderDirection==0 
        PointPrice=1-abs(IgrdY(Y,X)*Dx-IgrdX(Y,X,1)*Dy)/sqrt(Dy+Dx)/255;% multiple the gradient by curve normal sign not included
     else
          PointPrice=1-(IgrdY(Y,X)*Dx-IgrdX(Y,X,1)*Dy)/sqrt(Dy+Dx)/255*Gradient2BorderDirection;% multiple the gradient by curve normal sign included
     end;
 end
 

   function [PointPrice]=PointPrice11c()
 %Calculate Price as the scalar mutipication of  the normalized intensity change
 %normal to curve
 %I intensity image
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
   global I Y X Xb Yb Gradient2BorderDirection
     Dy=Y-Yb;
     Dx=X-Xb;
        if Gradient2BorderDirection==0  
               PointPrice=1-abs(I(Y,X)-I(Y+Dx,X-Dy ))/max([I(Y,X) I(Y+Dx,X-Dy ) 1]);
        else
             PointPrice=1-(I(Y,X)-I(Y+Dx,X-Dy ))/max([I(Y,X) I(Y+Dx,X-Dy ) 1])*Gradient2BorderDirection;
        end;
                PointPrice=PointPrice*HighPriceZone(Y,X); 
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function [PointPrice]=PointPrice12()
 %Calculate Price as the scalar mutipication of  the gradient normal and the path line at this point using the intensity image (yet another mode)
 %I intensity image
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
    global I Y X Xb Yb
     Dy=Y-Yb;
     Dx=X-Xb;
     PointPrice=(I(Y-Dx,X+Dy)-I(Y+Dx,X-Dy ))/255;
             PointPrice=PointPrice*HighPriceZone(Y,X); 
  end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function [PointPrice]=PointPrice12b()
 %Calculate Price as the scalar mutipication of  the gradient normal and the path line at this point using the intensity image (yet another mode)
 %I intensity image
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
    global I Y X Xb Yb Gradient2BorderDirection HighPriceZone
     Dy=Y-Yb;
     Dx=X-Xb;
     if Gradient2BorderDirection==0 
         PointPrice=1-abs(I(Y-Dx,X+Dy)-I(Y+Dx,X-Dy ))/255;
     else
         PointPrice=1-(I(Y-Dx,X+Dy)-I(Y+Dx,X-Dy ))/255*Gradient2BorderDirection;
     end;
             PointPrice=PointPrice*HighPriceZone(Y,X); 
  end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
     function [PointPrice]=PointPrice13()
 %Calculate Price as the scalar mutipication of  the normalize gradient normal and the path line at this point using the intensity image (yet another mode)
 %I intensity image
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
    global I Y X Xb Yb
     Dy=Y-Yb;
     Dx=X-Xb;
  
         PointPrice=1-(I(Y-Dx,X+Dy)-I(Y+Dx,X-Dy ))/max([I(Y-Dx,X+Dy) I(Y+Dx,X-Dy ) 1]);

 end
 
%}    
    
    

    
        

