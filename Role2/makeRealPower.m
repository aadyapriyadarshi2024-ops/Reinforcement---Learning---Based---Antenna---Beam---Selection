
function powerFcn = makeRealPower(T)
%MAKEREALPOWER Return a lookup function for received power in watts.

powerFcn = @lookupPower;

    function pW = lookupPower(i, j, angTx, angRx)
        a = find(abs(T.txAz - angTx) < 1e-9, 1);
        b = find(abs(T.rxAz - angRx) < 1e-9, 1);

        if isempty(a) || isempty(b)
            error('Requested steering angle is not in the lookup grid.');
        end

        if ~T.valid(i,j)
            pW = 0;
            return;
        end

        pDbm = T.txPowerDbm ...
             + T.txGainDb(i,j,a) ...
             - T.pathLossDb(i,j) ...
             + T.rxGainDb(i,j,b);

        pW = 10^((pDbm - 30)/10);
    end
end
