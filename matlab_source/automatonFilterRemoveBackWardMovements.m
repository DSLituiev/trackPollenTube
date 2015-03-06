function kymoThrInt = automatonFilterRemoveBackWardMovements(kymoThr)

T = size(kymoThr, 2);
L = size(kymoThr, 1);
%
kymoThrInt = int8(kymoThr./nanmax(kymoThr(:)));

step1 = true;
step2 = true;

for ll = L:-1:2    
    for tt = T-1:-1:2        
        %  |  |+1|       |+1|-1|  
        %  -------  =>   -------
        %  |+1|  |       |+1|  |
        if (kymoThrInt(ll,tt)==1) &&  (kymoThrInt(ll-1,tt+1) == 1) && step1
            kymoThrInt(ll-1,tt+1) = -1;
            kymoThrInt(ll-1,tt) = 1;
        end
        
        %  |  |+1|       |+1|-1|  
        %  -------       -------
        %  |<0|  |  =>   |+1|  |
        %  -------       -------
        %  |  |  |  =>   |+1|  |        
        if (kymoThrInt(ll,tt) <0) && (kymoThrInt(ll-1, tt+1) == 1)&& step2
            
            kymoThrInt(ll-1, tt-1 ) = 1;
            kymoThrInt(ll-1, tt+1 ) = -1;
            kymoThrInt(ll-1,tt) = -1;
        end
    end
end

figure
phandle = pcolor( double(kymoThrInt ) );
set( phandle , 'linestyle', 'none');
set(gca, 'yDir', 'reverse');
axis equal tight