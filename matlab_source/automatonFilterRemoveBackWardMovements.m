function kymoThrInt = automatonFilterRemoveBackWardMovements(kymoThr)

T = size(kymoThr, 2);
L = size(kymoThr, 1);
%
kymoThrInt = int8(double(kymoThr)./nanmax(double(kymoThr(:))));

step1 = true;
step2 = true;
step3 = true;
step4 = true;

for ll = 2:1:L%:-1:2    
    for tt = 2:1:T-1
        %  |  |+1|       |+1|-1|  
        %  -------  =>   -------
        %  |+1|  |       |+1|  |
        if (kymoThrInt(ll,tt)==1) &&  (kymoThrInt(ll-1,tt+1) == 1) && step1
            kymoThrInt(ll-1,tt+1) = -1;
            kymoThrInt(ll,tt+1) = 1;
        end
        
        %  |  |+1|       |+1|-1|  
        %  -------       -------
        %  |<0|  |  =>   |+1|  |
        %  -------       -------
        %  |  |  |  =>   |+1|  |        
        if (kymoThrInt(ll,tt) <0) && (kymoThrInt(ll+1, tt) == 1)  && step2 
            if (kymoThrInt(ll, tt+1) == 1)             
                % kymoThrInt(ll, tt) = 0;
                kymoThrInt(ll+1, tt+1 ) = 1;
                kymoThrInt(ll,tt+1) = -1;
            end
            if (kymoThrInt(ll-1, tt+1) == 1)
                % kymoThrInt(ll, tt) = 0;
                kymoThrInt(ll+1, tt+1 ) = 1;
                kymoThrInt(ll-1, tt+1) = -1;
            end
        end
        
         if (kymoThrInt(ll,tt-1) ==1) && (kymoThrInt(ll, tt+1) == 1)  && step3 
             kymoThrInt(ll, tt) = 1;
         end
%          if  (kymoThrInt(ll,tt) ==-1) && (kymoThrInt(ll-1,tt) ~= 0) && (kymoThrInt(ll+1,tt-1) ~=0) && step4 
%              kymoThrInt(ll, tt) = kymoThrInt(ll-1,tt);
%              kymoThrInt(ll+1, tt) = kymoThrInt(ll-1,tt);
%              kymoThrInt(ll+1, tt-1) = -1;
%          end

    end
end

% 
% for ll = L-1:-1:2    
%     for tt = T-1:-1:2
%          if  (kymoThrInt(ll,tt) ==-1) && (kymoThrInt(ll-1,tt) ~= 0) && (kymoThrInt(ll+1,tt-1) ~=0) && step4 
%              kymoThrInt(ll, tt) = kymoThrInt(ll-1,tt);
%              kymoThrInt(ll+1, tt) = kymoThrInt(ll-1,tt);
%              kymoThrInt(ll+1, tt-1) = -1;
%          end
%     end
% end
         
figure
subplot(2,1,1)
phandle = pcolor( double(kymoThrInt ) );
set( phandle , 'linestyle', 'none');
set(gca, 'yDir', 'reverse');
axis equal tight

subplot(2,1,2)
phandle = pcolor( double(int8(double(kymoThr)./nanmax(double(kymoThr(:))))) );
set( phandle , 'linestyle', 'none');
set(gca, 'yDir', 'reverse');
axis equal tight