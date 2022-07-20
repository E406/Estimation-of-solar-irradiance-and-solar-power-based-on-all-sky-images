clc
clear all
imgdir = dir(fullfile('J:\台電資料\照片\','*'));
dirfile =imgdir;
% dirfile = dir(fullfile('D:\Mike\japin\image\7月\','*'));
form = xlsread('D:\Mike\japin\DATA\台電資料\1to3太陽位置.xlsx');%太陽位置
form1 = xlsread('D:\Mike\japin\DATA\台電資料\lstm_1to3.xlsx');%實際日射量

month = 1; %月份-
day = 1;%日數
hour = 11;
cumulativedays = [0;31;60;91;121;152;182;213;244;274;305;335];
LSTM = 120; %本地標準時間子午線
y1 = 260;
d = cumulativedays(month,:) + day;
j=4;
solar = form(1:(31*661),1:2);
% solar = form((1+31*661):20491+(28*661),1:2);
M3_SMT781 =0;
jj=[63:93];
tic;
 for j=jj
%     if(j==12)
%         j=23;
%     end
    %日期換算累積天數
    d = cumulativedays(month,:) + day;
    files = dir(fullfile('J:\台電資料\照片\',dirfile(j).name,'*.jpg'));
    if(781 <= length(files))  
        for m=121:1:781;
            image = imread(strcat('J:\台電資料\照片\',dirfile(j).name,'\',files(m).name));
            img260 = imresize(image,[260,260]);
            img260=imrotate(img260,180);
            sx = round(solar(m-120,1));
            sy = round(solar(m-120,2));
            %% zenith angle
            hour = 7;
            hour=hour+0.0165*(m-119);
            longitude = 121.42; %經度
            latitude = 24.99; %緯度
            B = (360*(d-81))/365;
            EoT = 9.87*sind(2*B)-7.53*cosd(B)-1.5*sind(B); %天文時差=真太陽時-均太陽時
            TC = EoT+4*(longitude-LSTM); %時間修正因子
            LST = TC/60 + hour; %真太陽時間
            HRA = 15*(LST-12); %時角
            SDA = 23.45*sind(B);
            %太陽高度角
            EL = asind((sind(SDA)*sind(latitude))+(cosd(SDA)*cosd(latitude)*cosd(HRA)));
            if EL<0 
            EL=0;
            end
            %太陽方位角
            AZ = acosd((sind(SDA)*cosd(latitude)-(cosd(SDA)*sind(latitude)*cosd(HRA)))/cosd(EL));
            if LST>=11.9 AZ = 360 - AZ;end
            AZ = AZ +90;
            ELr = (EL*pi)/180;AZr = (AZ*pi)/180;
            %% GHI
        %     Isc = 1366.1;
        %     T = 2*pi*(d-1)/365;
        %     E0 = 1.00011+0.034221*cos(T)+0.00128*sin(T)+0.000719*cos(2*T)+0.000077*sin(2*T);
        %     %E0 = 1+0.033*cos((360+d)/365.25);
        %     GHI(m,1) = 0.8277*E0*Isc*((sin(ELr))^(1.3644*exp(-0.0013*(90-ELr))));
        %     %G(i,1) = 0.8277*E0*Isc*((sind(EL(i,1)))^(1.3644*exp(-0.0013*(90-EL(i,1)))));
        %     if GHI(m,1)<0 GHI(m,1)=0; end;
            %% Target points
            R1 = rand(5000,2);
            phi = 2*pi.*R1(:,1);
            sita = acos(sqrt(R1(:,2)));
            x = sin(sita).*cos(phi);
            y = sin(sita).*sin(phi);
            z = cos(sita);
            location = [x,y];

            % plot(x,y,'.r');

            solardx = sx-130; 
            solardy = sy-130;
            xt = 130*sin(sita).*cos(phi)+130+solardx;
            yt = 130*sin(sita).*sin(phi)+130+solardy;
            aa= find(xt>260); xt(aa) = 0;yt(aa) = 0;
            aa= find(xt<0); xt(aa) = 0;yt(aa) = 0;
            aa= find(yt>260); yt(aa) = 0;xt(aa) = 0;
            aa= find(yt<0); yt(aa) = 0;xt(aa) = 0;
            aa= find(round(xt)==0); yt(aa) = [];xt(aa) = [];
            aa= find(round(yt)==0); yt(aa) = [];xt(aa) = [];
            k = length(xt);
            %% Luminance
            R = img260(:,:,1);G = img260(:,:,2);B = img260(:,:,3);
            R = im2double(R);G = im2double(G);B = im2double(B);
            Y = 0.2126*R + 0.7152*G + 0.0722*B;

            for i =1:1:k
            a = round(xt(i)); b = round(yt(i));
            if Y(a,b)==0;
                xt(i) = 0; yt(i) = 0;
            end
            end
            aa= find(round(xt)==0); yt(aa) = [];xt(aa) = [];
            aa= find(round(yt)==0); yt(aa) = [];xt(aa) = [];
            kk = length(xt);

        %     Yi = 255.*(Y./255).^2.2;
            Yi = 255.*Y;
        %     Yi = 255.*(Yi./255).^2.2;
            Yi1 = (Yi).^2.2;

            Sum = 0;
            for i=1:1:kk
            a = round(xt(i)); b = round(yt(i));
            Sum = Sum + Yi1(a,b);
            end
            N = Sum/kk;

    %         Kc=0.18;
            Kc=0.2;
            fs = 1.47;et = 0.1; Ls =1000; %相機參數et曝光時間 Ls圖像亮度 做成變數 
        %     S = ((fs^2)*(N/(Kc*Ls)))/et;
        %     Lr = N*((fs^2)/S*et);
            Lr = N*((fs^2)/Kc*et); %有問題的地方
            L(m-120,1) = Lr*sind(EL);
            S(m-120,1) = 0.0138*L(m-120,1)-39.896;
        end
    else
        M3_SMT781 = M3_SMT781+1;
        M3__than_781( M3_SMT781) = day;
        S(1:661,1) =1111111;
%         j=j+1
%         day = day+1;
    end
        S_all_data((1+(j-jj(1))*661):(661+(j-jj(1))*661),2)=S;
        S_all_data((1+(j-jj(1))*661):(661+(j-jj(1))*661),1)=j-3;
    %     if(j>=23)
    %         S_all_data((1+(j-15)*180):(180+(j-15)*180))=S(121:781);
    %     else
    %         S_all_data((1+(j-4)*180):(180+(j-4)*180))=S(121:781);
    %     end    
%         j=j+1
%         day=day+1;
        everytime =toc
end
    S_all_data= S_all_data';
    ss = find( S_all_data<0); 
    S_all_data(ss) = 0;
    S_all_data= S_all_data';
    alltime=toc
    ss = find(S<0); 
    S(ss) = 0;
    A = S(119:779)+1;
    B = form1(:,4)+1;
    A1 = log10(A);
    B1 = log10(B);
    C = form1(:,5);
    RMSE = sqrt(mean((S(301:480)-form1(1:180,2)).^2));
    MAE = mae(S(301:480),form1(1:180,2));
    nRMSE = RMSE/(max(form1(1:180,2))-min(form1(1:180,2)));
    
    RMSLE = sqrt(mean((log(S(119:779)+1)-log(form1(:,4)+1)).^2));
    RMSLE1 = sqrt(mean((log(form1(:,5)+1)-log(form1(:,4)+1)).^2));
    RMSE1 = sqrt(mean((A-C).^2));
    Results = [MAE;RMSE;nRMSE];
    figure(1)
    plot(S_all_data,"r");
    hold on 
%     plot(GHI(119:779));
%     hold on
    plot(form1(1:661,22),"b");
    legend("估計","實際")
    grid on;
    hold off