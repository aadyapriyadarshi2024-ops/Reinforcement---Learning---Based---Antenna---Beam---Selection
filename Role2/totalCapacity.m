
function C = totalCapacity(angles, powerFcn)
%TOTALCAPACITY Total capacity of the 2 Tx / 2 Rx scenario.
%
% angles = [aTx1 aTx2 aRx1 aRx2] in degrees.
% powerFcn(i,j,angTx,angRx) returns received power in watts.
%
% Receiver j is served by transmitter j; the other transmitter
% contributes interference.

B = 400e6;
noiseW = physconst('Boltzmann') * 300 * B;

aTx = angles(1:2);
aRx = angles(3:4);

P = zeros(2,2);

for i = 1:2
    for j = 1:2
        P(i,j) = powerFcn(i,j,aTx(i),aRx(j));
    end
end

C = 0;

for j = 1:2
    wanted = P(j,j);
    interference = sum(P(:,j)) - wanted;
    sinr = wanted / (noiseW + interference);
    C = C + B * log2(1 + sinr);
end
end
