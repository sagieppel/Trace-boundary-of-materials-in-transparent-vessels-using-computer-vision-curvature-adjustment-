function  [AvWidth,MaxWidth]=VesselAvrgAndMaxWidth(By,Bx)
%Given list of coordinates for boundary points (Bx,By) of the vessel
%find the average height and width and max width and height of the vessel
%in pixels
AvWidth=double(0);%vessel (contour) average width
MaxWidth=double(0);%Vessel (contour) maximal width, the largest horizontal distance between two points on the same line in the vessel conotour
N=0;%number of lines
global  MaxX MaxY MinX MinY
MaxX=max(Bx);
MaxY=max(By);
MinX=min(Bx);
MinY=min(By);
global Ibor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%found max and average vessel width%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for fy=MinY:1:MaxY
    Xmn=MaxX;
    Xmx=MinX;% min and max edge x in this line
%==============scan all edges in the line find the left most and right most edges for line==========================================================================================================
  for fx=MinX:1:MaxX
        if (Ibor(fy,fx)==1)
           if (fx<Xmn) Xmn=fx;
           elseif (fx>Xmx) Xmx=fx;
           end 
        end
  end;
  %========================================================================================================================
     AvWidth= double(AvWidth)+double(abs(Xmx-Xmn)/(MaxY-MinY));% add line width to average
    if (abs(Xmx-Xmn)>MaxWidth) MaxWidth=abs(Xmx-Xmn); end;% if line width larger then previous MaxLine width set it as the new maximal vessel width
end;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
