function auxillary_bnds = min_speed_boundaries(dx, large_bnds)

auxillary_bnds = NaN(numel(large_bnds),2);

for kk = 1:numel( large_bnds )
    ll = large_bnds(kk);
    if ll > 1 && ll < numel(dx)-1;
        %===========================
        ii = ll;
        jj = ll-1;
        if abs(dx(jj)) < abs(dx(ii))
            flag_wrong_side = false;
        else
            flag_wrong_side = true;
        end
        while abs(dx(jj)) < abs(dx(ii)) || flag_wrong_side
            ii = ii - 1;
            jj = jj - 1;
            if jj == 0
                break
            end
            if abs(dx(jj)) < abs(dx(ii))
                flag_wrong_side = false;
            end
        end
        auxillary_bnds(kk,1) = ii;
        %===========================
        ii = ll;
        jj = ll+1;
        if abs(dx(jj)) < abs(dx(ii))
            flag_wrong_side = false;
        else
            flag_wrong_side = true;
        end
        while abs(dx(jj)) < abs(dx(ii))|| flag_wrong_side
            ii = ii + 1;
            jj = jj + 1;
            if jj == numel(dx)
                break
            end
            if abs(dx(jj)) < abs(dx(ii))
                flag_wrong_side = false;
            end
        end
        auxillary_bnds(kk,2) = ii;
        %===========================
    end
end

end