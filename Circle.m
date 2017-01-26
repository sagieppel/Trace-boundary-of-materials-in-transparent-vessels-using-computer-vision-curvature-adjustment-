function [ MCircle ] = Circle( R )
%Make matrix with a binary circle of ones in radious R
MCircle=zeros(round(R*2));
for fx=1:2*R
    for fy=1:2*R
        if ((fx-R)^2+(fy-R)^2<=R^2)
            MCircle(fy,fx)=1;
        end;
    end;
end;

end

