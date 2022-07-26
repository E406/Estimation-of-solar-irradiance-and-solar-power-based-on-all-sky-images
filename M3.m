clc
clear
close all

imgdir = dir(fullfile(ImgFolder,'*'));
dirfile =imgdir;
form = xlsread('Position.xlsx');
form1 = xlsread('Irradiance.xlsx');
month = 1; 
day = 1;
hour = 11;
cumulativedays = [0;31;60;91;121;152;182;213;244;274;305;335];
LSTM = 120; 
y1 = 260;
d = cumulativedays(month,:) + day;
solar = form(:,1:2);
M3_SMT781 =0;
jj=[4:4];
tic;
 for j=jj
    d = cumulativedays(month,:) + day;
    files = dir(fullfile(ImgFolder,dirfile(j).name,'*.jpg'));
    fprintf('j=%d',j)
    if(781 <= length(files))  
        for m=121:1:781
            image = imread(strcat(ImgFolder,dirfile(j).name,'\',files(m).name));
            img260 = imresize(image,[260,260]);
            img260=imrotate(img260,180);
            sx = round(solar(m-120,1));
            sy = round(solar(m-120,2));
            %% zenith angle
            hour = 7;
            hour=hour+0.0165*(m-119);
            longitude = 121.42; 
            latitude = 24.99; 
            B = (360*(d-81))/365;
            EoT = 9.87*sind(2*B)-7.53*cosd(B)-1.5*sind(B); 
            TC = EoT+4*(longitude-LSTM); 
            LST = TC/60 + hour; 
            HRA = 15*(LST-12); 
            SDA = 23.45*sind(B);
            EL = asind((sind(SDA)*sind(latitude))+(cosd(SDA)*cosd(latitude)*cosd(HRA)));
            if EL<0 
            EL=0;
            end
            AZ = acosd((sind(SDA)*cosd(latitude)-(cosd(SDA)*sind(latitude)*cosd(HRA)))/cosd(EL));
            if LST>=11.9 AZ = 360 - AZ;end
            AZ = AZ +90;
            ELr = (EL*pi)/180;AZr = (AZ*pi)/180;
            %% Target points
            R1 = rand(5000,2);
            phi = 2*pi.*R1(:,1);
            sita = acos(sqrt(R1(:,2)));
            x = sin(sita).*cos(phi);
            y = sin(sita).*sin(phi);
            z = cos(sita);
            location = [x,y];
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
            Yi = 255.*Y;
            Yi1 = (Yi).^2.2;
            Sum = 0;
            for i=1:1:kk
            a = round(xt(i)); b = round(yt(i));
            Sum = Sum + Yi1(a,b);
            end
            N = Sum/kk;
            Kc=0.2;
            fs = 1.47;et = 0.1; Ls =1000; 
            Lr = N*((fs^2)/Kc*et); 
            L(m-120,1) = Lr*sind(EL);
            S(m-120,1) = 0.0138*L(m-120,1)-39.896;
        end
    else
        M3_SMT781 = M3_SMT781+1;
        M3__than_781( M3_SMT781) = day;
        S(1:661,1) =1111111;
    end
        S_all_data((1+(j-jj(1))*661):(661+(j-jj(1))*661),2)=S;
        S_all_data((1+(j-jj(1))*661):(661+(j-jj(1))*661),1)=j-3;       
 end
S_all_data= S_all_data';
ss = find( S_all_data<0); 
S_all_data(ss) = 0;
S_all_data= S_all_data';

figure(1)
plot(form1(1:661,1),"b");
hold on 
plot(S_all_data(:,2),"r");
legend("Estimation","Actual")
grid on;
hold off