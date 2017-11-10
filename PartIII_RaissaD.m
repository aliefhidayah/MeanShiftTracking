%Assignment 3 - Raissa D'Souza - CMPT 412 - 301206045 
%%%%%%%%%%%%%%%%%% PART III %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load('CMPT412_blackcup.mat'); %uncomment this line if using backcup
load('CMPT412_bluecup.mat'); %uncomment this line if using bluecup

%[row_cup, col_cup, color_cup, frame_num] = size(blackcup); %uncomment this line if using backcup
[row_cup, col_cup, color_cup, frame_num] = size(bluecup);  %uncomment this line if using bluecup


%lastframe = blackcup(:,:,:,frame_num); %uncomment this line if using backcup
lastframe = bluecup(:,:,:,frame_num); %uncomment this line if using bluecup

%first = blackcup(:,:,:,1);  %uncomment this line if using backcup
first = bluecup(:,:,:,1); %uncomment this line if using bluecup



figure;
imshow(first);
[mypoint1,mypoint2] = ginput(2); %specify the region of the cup to track for blackcup.mat file
cup = first(mypoint2(1): mypoint2(2), mypoint1(1):mypoint1(2),:); 
cup =  floor((double(cup)* 8)/265);
[rowc, colc, colors] = size(cup);
%cup = first(255:365, 30:110,:); %use if having trouble with ginput for black cup 
%cup = first(167:335, 27:157,:); %use if having trouble with ginput for blue cup 
figure;
imshow(cup);


%use swain and ballard method from part II to find the object in the first frame
firsth =  floor((double(first)* 8)/265); %convert first frame into a 3bit image
cuphist = hist_maker(rowc, colc, cup); %get histogram for cup 
framehist = hist_maker(row_cup, col_cup, firsth); %get histogram for first frame
backimage = backprojection(cuphist, framehist, firsth); %get backprojection image
filter = imgaussfilt(backimage, 30); %use gaussian filter
[maxpoint, coord] = max(filter(:)); %find brightest pixel
[x , y] = ind2sub(size(filter),coord); %return coordinates of the cup 
point = [x,y];

%point = [310,65]; %can also approximate the highest density of the cup without swain-ballard backprojection
                    %Only uncomment this line if not using the above swain
                    %and ballard method 
                    
first = insertMarker(first,[point(2) point(1)]); %plot the highest density of the cup 
imshow(first);

for i = 1: frame_num
    
    %current_frame = blackcup(:,:,:,i);  %uncomment this line if using backcup
    current_frame = bluecup(:,:,:,i);  %uncomment this line if using bluecup
    
    %track_im = back_hist(current_frame, blackcup, cup);
    track_im = back_hist(current_frame, bluecup, cup);

    
    for r = 1:5 %run mean shift a few times to get a better approximation of denisty 
        mx = tracker_mean(track_im, point(1), point(2));
        point = round(point + (mx)*0.2);
        
    end
    
    current_frame = insertMarker(current_frame,[point(2) point(1)]);
    figure;
    imshow(current_frame);
    lastframe = insertMarker(lastframe, [point(2),point(1)]);
    
    
end
figure;
imshow(lastframe);



function backimage  = back_hist(frame1, video, cup)

    [row, col, color, frame] = size(video); %Get the #rows #cols #colorchannels #frames
    
    frame1 =  floor((double(frame1)* 8)/265); %reduce image to a 3 bit image
    
    [rowc, colc, colors] = size(cup); %Get #rows #cols #colorchannels


    cuphist = hist_maker(rowc, colc, cup); %get histogram of cup
    framehist = hist_maker(row, col, frame1); %get histogram of frame
   
   
    backimage = backprojection(cuphist, framehist, frame1); %get backprojection image




end



function mat1 = hist_maker(row, col, data)
    %split into color channels 
    red = data(:,:,1);
    green = data(:,:,2);
    blue = data(:,:,3);


 %create a 3D matirix to hold all the for the red and green colors buckets 
 mat1 = zeros(8,8,8);

    for i = 1:col
        for j = 1:row
            r = red(j,i)+1;
            g = green(j,i)+1;
            b = blue(j,i)+1;
            mat1(r,g,b) = mat1(r,g,b) +1;  %insert color into coorisponding location
        end
    end
end


function bpimage = backprojection(hist_M, hist_I, M)
    
    [row, col, channel] = size(M);
    bpimage = zeros(row, col);
    %split into color channels 
    red = M(:,:,1);
    green = M(:,:,2);
    blue = M(:,:,3);

    
    for i = 1:row
        for j = 1:col
            r = red(i,j)+1;
            g = green(i,j)+1;
            b = blue(i,j)+1;
            bpimage(i,j) = min((hist_M(r,g,b)/hist_I(r,g,b)), 1); %take minimum 
        end
    end
end


function Mx  = tracker_mean(backproj, x , y)
    %backproj is the backprojected image given by the swain and ballard
    %method in part two 
    %y and x are the coordinates of the center of the cup
    
    PointX = backproj(x,y); %get the pixel value at the center of the cup 
    
    [row, col, bpColor] = size(backproj); %get the number of rows and columns and color channels
    
    SumTop = [0,0]; %variable to hold the top part of the mean equation 
    SumBot = 0; %variable to hold the bottom of the mean equation 
        
    for i = max(x-80,1):min(x+80,row) %using two for loops go through every pixel in the window 
        for j = max(y-45,1):min(y+60,col)
            
            PointXi = backproj(i,j); %get the value of the pixel at pixel(i,j)
            top = (-1*(((PointX-PointXi).^2)/10)); %compute the top part of the mean function (||x - xi||^2)/h
                                                    % where h is an arbitrary constant                                                                                     
            top = top * [i,j];  %multiply by Xi 
            SumTop = SumTop + top; %sum all the neumorator values together
            SumBot = SumBot + (-1*((((PointX-PointXi).^2)/10))); %perform the bottom part of the mean equation
                                                                 %(||x-xi||^2)/h where h is arbitrary constant
                                                                 
        end
    end 
   result = SumTop/SumBot; %divide the Sum of neumerator by Sum of denominator
   Mx = result - [x,y]; %perform last step of mean shift function and subtract x from the result to get the mean 
                        %shift vector 
   return
            
end            