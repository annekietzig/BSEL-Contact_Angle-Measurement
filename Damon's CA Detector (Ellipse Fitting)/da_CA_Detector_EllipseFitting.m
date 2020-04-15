clear
format short
close all

% ----------------------   MAIN ANALYSIS PARAMETERS   ---------------------
FirstFrame=1 %Set as 1 unless want to crop start of video
LastFrame=[] %set as [] unless want to crop end of video
bline=142; %baseline position, MUST SET MANUALLY !
bal= 100; %Used to find the center of the needle
threshold=15; %Edge detection program threshold. Should be about 15-25
fSkip=5; %how often to refresh plot
adjustfac=5; %space between baseline and a crop line, above which ellipse fitting is done
finalcutter=-70; %how many pts from drop's left side to start taking pts for ellipse fitting. Best position is about 135o in polar coordinates
flipLR=0; %The code only measures left side of drop. set =1 to measure the right side
CAmin=130; %assume erroneous results outside this window
CAmax=170;
BLineTrack=1; %Set =0 or 1 for 2 different visualzations of baseline movement
ellipsecropX=10; %This truncates the ellipse after the left-most intersect to avoid having 2 intersectsions on the baseline. Set as about 5-10 depending on the CA. Blue ellipse should cut through the pink baseline for a few pixels without curving back up.
PauseTime=0.1;
addpath('C:\Users\damon\Desktop\Big Files\ARCA'); %Where the video files are located on your compute
% -------------------------------------------------------------------------

vidObj = VideoReader('P100 3.avi');
numFrames = ceil(vidObj.FrameRate*vidObj.Duration);

% ----------------------   INITIAL IMAGE CHECK   --------------------------
I0 = read(vidObj,FirstFrame); %Read video file
% I0 = flipdim(I0,1); %flip it
if flipLR==1; I0=fliplr(I0); end
I0=I0(:,:,1);
[m,n]=size(I0); %find size of image in pixels

centfind=I0(20,:); %Find center location
centloc=find(centfind<bal);
cent=mean(centloc);

FigHandle = figure;%set figure size and position for later
set(FigHandle, 'Position', [300, 50, 1200, 700]);

subplot(3,2,[1 2 3 4])
imshow(I0); %show image
hold on
colormap(gray)
plot([0 n], [m-bline m-bline],'-m','LineWidth',1) %(m) Baseline
text(20,m-bline+15,'Base Line','FontSize',14,'Color','m')
plot([0 n], [m-bline-adjustfac m-bline-adjustfac],'-b','LineWidth',1)%(b) find line
text(n-120,m-bline-15-adjustfac,'White Line','FontSize',14,'Color','b')
plot([cent cent],[0 m],'-r')% (r) center line
text(cent+5,20,'Center Line','FontSize',14,'Color','r')

subplot(3,2,[5 6])
image(I0/4); %show image
hold on
colormap(gray)
plot([0 n], [m-bline m-bline],'-m','LineWidth',2)
plot([0 n], [m-bline-adjustfac m-bline-adjustfac],'-b','LineWidth',2)
ylim([m-bline-adjustfac-5 m-bline+5])
xlim([min(centloc)-50 max(centloc)+50])

disp('Press space to continue if Baseline and Whiteline look good!')
pause
close
% ----------------------   END INITIAL IMAGE CHECK   ----------------------

FigHandle = figure;%set figure size and position for later
set(FigHandle, 'Position', [400, 50, 750, 700]);

% ----------------------   MAIN LOOP   ------------------------------------
count=0;
problems=[];
if numel(LastFrame)>0;     numFrames=LastFrame;    end
for ii=FirstFrame:3:numFrames
    count=count+1;

    I0 = read(vidObj,ii); %Read video frame
    if flipLR==1; I0=fliplr(I0); end
    I0 = flipdim(I0,1);
    I0=I0(:,:,1); %Remove 3rd Dimension

    centfind=I0(m-20,:); %find the center of the drop
    cent=find(centfind<bal);
    cent=mean(cent);

% ----------------------   Image Processing   ------------------------------------
    edges1 = subpixelEdges(I0, threshold); %Edge finding protocol
    x=edges1.x;
    y=edges1.y;

    surfcount=numel(find(y<bline+20 & y>bline-20));
    if surfcount<100 %check that the threshold is set correct and pause and show if needed
        disp('Low surface count. Check threshold!')
    end
    
    [ys,I] = sort(y,'descend'); %"s=sorted" sort the resulting coordinates in order
    xs=x(I);

    surfkill=find(ys<bline+adjustfac); %remove all the surface's points 
    xas=xs; xas(surfkill)=[];%a="above" the surface
    yas=ys; yas(surfkill)=[];

    yls=yas(find(xas<cent)); %"left sorted" keep only those left of center
    xls=xas(find(xas<cent));
    
    Ia=I0; %Copy working picture and make "Adapted" version to measure
    for j=1:numel(xls) %Turn everything right of the drop's left edge black to eliminate the white spot and many other fatures that can confuse the ellipse fitting protocol
        Ia(round(yls(j)),[round(xls(j))+3:end])=0;
        Ia([round(yls(j))-1 round(yls(j))+1] ,[round(xls(j))+5:end])=0; %Try the code line >>image(Ia) to see what this looks like if you need to
    end

    %Redo the edge finding protocol using the adapted image.
    edges2 = subpixelEdges(Ia, threshold); %Edge finding protocol
    x2=edges2.x;
    y2=edges2.y;
    
    [ys,I] = sort(y2,'descend'); %"sorted" sort the resulting coordinates in order
    xs=x2(I);

    surfkill=find(ys<bline+adjustfac); %remove all the surface's points 
    xas=xs; xas(surfkill)=[];%a="above" the surface
    yas=ys; yas(surfkill)=[];

    yls=yas(find(xas<cent)); %"left sorted" keep only those left of center
    xls=xas(find(xas<cent));
 
    leftside=find(xls==min(xls)); %find the point furthest to the left
    leftside=leftside(end);
    xlf=xls(leftside+finalcutter:end); %'left final' points are only well below that point
    ylf=yls(leftside+finalcutter:end);    

% ----------------------   Ellipse Fitting   ------------------------------------
    try
        [z, A, b, apl] = fitellipse([xlf';ylf'], 'linear');
    catch
        problems=[problems count] %This will store frame counters that ellipse fitting failed on to eliminate from final dataset
    end
    npts = 300; %Create x-y vectors of ellipse positions
    t = linspace(0, 2*pi, npts);
    Q = [cos(apl), -sin(apl); sin(apl) cos(apl)];
    X = Q * [A * cos(t); b * sin(t)] + repmat(z, 1, npts);
    xe=X(1,:); %get its x-y coordinates for use below
    ye=X(2,:);
    
% ----------------------   Ellipse/Baseline Intersection Seeking   ------------------------------
    t=0;
    nearish=[];
    while numel(nearish)==0 %This searches within 1 or 2 pixels of the baseline for ellipse points that are very close to that y-position 
        t=t+1;
        nearish=find(abs(ye-bline)<t); %and records the indexes of those points
    end
    
    ellipsecropn=min(xe(nearish))+ellipsecropX;%Delete all points of ellipse past a few pixels right of the left-most intersection
    
    if numel(ellipsecropn)==0;
        disp('ellipse fitting failed !!')
        problems=[problems count];
    else
    ye(find(xe>ellipsecropn))=[]; %Delete all points of ellipse past a few pixels right of the left-most intersection
    xe(find(xe>ellipsecropn))=[];
    end
 
    yfind=abs(ye-bline); %Find the pt closest to baseline
    
    disp([count,ii])
    ei=find(yfind==min(yfind)); %starting with its index
    if numel(ei)>1
        ei=ei(end); %index position of baseline point
    end

    xc=xe(ei); %current intersect position of ellipse on baseline
    yc=ye(ei);

    de=diff(ye)./diff(xe); %then find the derivative 
    if ei==numel(yfind);
        d= (de(ei-2)+de(ei-1))/2; %in case of counting error
    elseif ei==1;
        d= (de(ei)+de(ei+1))/2; %in case of counting error
    else
        d= (de(ei-1)+de(ei))/2; %at that particular point
    end
        

    Dl(count)=atand(d)+180; %CA in degrees
    pl(count)=xc; %base position tracker 1
    pl2(count)=min(find(Ia(bline+adjustfac+1,:)==0));%base position tracker 2
    
% ----------------------   END ELLIPSE FITTING   --------------------------

% ----------------------   PLOTTING   -------------------------------------
    if ii==1 | round(ii/fSkip)==ii/fSkip
  
        subplot(3,2,[1 2 3 4]) %Top plot
        hold on
        image(I0/4);    colormap(gray)
        plot(x,y,'.r','Markersize',6) %All edges
        plot(xas,yas,'.','Markersize',6,'Color',[0.7 0.3 0.7]) %Above-line points
        plot(xlf,ylf,'.g','MarkerSize',8) %Fitting points
        ylim([0 m]);    xlim([0 n])
        plot(xe, ye,'-b') %Ellipse
        plot([xc xc-200],[yc yc+200*tand(180-Dl(count))],'-m') %Tangent line
        dlstr=num2str(Dl(count)); %Display CA
        dlstr=dlstr([1:3]);
        text(50,bline+20,dlstr,'FontSize',14)

        subplot(3,2,[5 6]) %Bottom plot
        hold on
        image(Ia/4);    colormap(gray)
        plot(x2,y2,'.r','Markersize',10) %All edges
        plot(xas,yas,'.c','Markersize',10) %Above-line points
        plot(xlf,ylf,'.g','MarkerSize',15) %Fitting points
        ylim([0 m]);    xlim([0 n])
        plot(xe, ye,'-b') %ellipse
        plot(xc,yc,'^c','MarkerSize',10,'LineWidth',3) %Current position
        plot([0 n], [bline bline],'-m','LineWidth',1) %Baseline
        plot([xc xc-200],[yc yc+200*tand(180-Dl(count))],'-m','LineWidth',2) %Tangent line
        xlim([xc-50 xc+20]);    ylim([bline-5 bline+20])
        pause(PauseTime)
    end
% ----------------------   END PLOTTING   ---------------------------------
end

% ----------------------   FINAL GRAPHING   -------------------------------

kills=find(Dl<130 | Dl>170); %Remove points outside of reasonably expected window
Dl_k=Dl;
Dl_k([kills, problems])=0; %kill any data points where ellipse fitting failed
pl_k=pl;
pl_k([kills, problems])=0;
pl2_k=pl2;
pl2_k([kills, problems])=0;

close all
figure
hold on
base=[1:numel(Dl_k)];
plot(base,Dl_k,'b.')
title('left')

if BLineTrack==1;
    pl2d=diff(pl2_k);
    pl3=pl2d(1:end-4)+pl2d(1+1:end-4+1)+pl2d(1+2:end-4+2)+pl2d(1+3:end-4+3)+pl2d(1+4:end-4+4);
    pl3=abs(pl3);
    pl3(find(pl3==1))=0;
    pl3=[0 pl3 0 0 0 0];
    pl3=pl3.^2;
    pl4=pl3/max(pl3);
    sc=max(Dl_k)-min(Dl_k);
    graphpl=min(Dl_k)+pl4*(max(Dl_k)-min(Dl_k));
else
    pdl=abs(diff(pl_k));
    pdl=pdl/max(pdl);
    sc=max(Dl_k)-min(Dl_k);
    graphpl=min(Dl_k)+pdl*(max(Dl_k)-min(Dl_k));
end

plot([min(Dl_k) graphpl min(Dl_k)],'m')
ylim([CAmin CAmax])

clipout=[pl_k' pl2_k' Dl_k'];



%%%%%%%%%%%%%%    To return data from excel in a matrix called 'a', so that
%%%%%%%%%%%%%%    you can use it in the final graphing section without
%%%%%%%%%%%%%%    rerunning the code

% a=[        COPY DATA HERE        ]
% pl_k=a(:,1);
% pl2_k=a(:,2);
% Dl_k=a(:,3);
% pl_k=pl_k';
% pl2_k=pl2_k';
% Dl_k=Dl_k';
