%%Program to read-resize-organize color images called from URL's and run
%%PCA for euclidian distance measures (similarity links) for artwork to
%%artwork network

% As of 12/9/2019: This program is built to analize artwork-artwork
% interactions with euclidian distance similarity links; Raw data is prone
% to error and needs to be checked; will make further sophistication to the
% network ability, linkage importance proof and dynamic interactions.

%Read table and call urls for images -> RBG matrices

full_table = readtable('tester.xlsx'); % *(NEED TO RECHECK RAW DATA AND CORRECT ERRORS)*
[num,~] = size(full_table);
image_archive = cell(1,num); % Cell holder for all images
%NodeNo =  full_table(:,1);
%ArtistNo = full_table(:,3);
%ArtistNames =  full_table(:,5);
URLlist = string(table2array(full_table(:,4))); % URLs for all images

for i = 1:num
    options = weboptions('Timeout', 30); % If error, "Cannot read URL," run loop at error image count and continue 
    url_img = webread(URLlist(i), options);
    resized_img = imresize(url_img, [300 300]); % Make images same size for PCA
    image_archive{1,i} = resized_img; % save uint8 mtx times 3 (RBG) into cell
    if mod(i,50) == 0
        fprintf('Loading Image Number: %d\n', i);
    end
end



load chirp.mat;
sound(y);

% for i = 1:10497 % Remove any B&W images based on uint8 size
%     if sum(size(image_archive{i})) < 603
%         image_archive(i) = [];
%     end
% end

image_archive_logic = cellfun('isempty', image_archive);
[~,num] = size(image_archive);
lister = [];
counter = 1;
for flow = 1:num
    test = image_archive_logic(flow);
    if test == 1
        lister(counter,1) = flow;
        counter = counter + 1;
    end
end
for flow2 = 1:counter-1
    image_archive(lister(flow2,1)) = [];
    uniqset(lister(flow2,1),:) = [];
end

image_archive = image_archive(~cellfun('isempty',image_archive)); % Remove any B&W images based on uint8 size
[num, ~] = size(image_archive);

%% Organize RNG mtx's for PCA (every rand ~2000), run PCA and save PCs

tPCAscore = [];
components = 100; % PCA components to use for downstream analysis
artist = [];

universalcountindex = 0;
universalcount = 1;

for groupno = 1:5 % Seperate total data into 5 parts to do PCA in chuncks (due to computational limitation)
    count = 1;
    clear group; clear randartist; clear holder;
    for j = 1:num % Edit ending range from new image_archive size
       
        if table2array(full_table(j,2)) == groupno % Call random generated groups (1-5) for batch PCA computing
            holder = image_archive{j};
            holderR = reshape(holder(:,:,1)',[],1);
            holderB = reshape(holder(:,:,2)',[],1);
            holderG = reshape(holder(:,:,3)',[],1);
            holderRBG = vertcat(vertcat(holderR,holderB),holderG); % 1 long pixal vector for each image
            group(:,count) = holderRBG;
            randartist(count,:) = full_table(j,3); % artist marking for each artwork loaded *(THIS NEEDS TO BE FIXED)*
            
            count = count + 1;
            universalcount = universalcount + 1;
            
            if mod(universalcount,50) == 0
                fprintf('Loading PCA Number: %d\n', universalcount);
            end
            
        end
    end
    universalcountindex(groupno+1,1) = universalcount - 1;
    [coeff,score,latent] = pca(transpose(cast(group,'single'))); % Load PCA -(after transpose): row=artwork,column=PCs
    tPCAscore((universalcountindex(groupno,1)+1):(universalcountindex(groupno+1,1)),:) = score(:,1:components); % Organize PCA data with correct artwork number
    artist((universalcountindex(groupno,1)+1):(universalcountindex(groupno+1,1)),:) = table2array(randartist);
end

%% PC distributions / figures and comparisons for artists/artworks

[num, ~] = size(image_archive);
combine = [artist,tPCAscore];
sortcombine = sortrows(combine);

distance = [];
for m = 1:num
    for n = 1:num
    
    distance(n,m) = sum(abs(tPCAscore(m,:)-tPCAscore(n,:))); % Euclidian distance measures from PCs
        
    end
end

figure(1);
grid on; axis square equal;
scatter3(tPCAscore(:,1),tPCAscore(:,2),tPCAscore(:,3),'.');
hold on;
imageNum = size(image_archive,1);
imageWidth = 20;
for i = 1:imageNum
    img = imresize(image_archive{i}, [imageWidth imageWidth]);
    x = tPCAscore(i,1);
    y = tPCAscore(i,2);
    z = tPCAscore(i,3);
    width = imageWidth;
    xImage = [x x+width; x x+width];   % The x data for the image corners
    yImage = [y y; y y];             % The y data for the image corners
    zImage = [z z; z-width z-width];   % The z data for the image corners
    surf(xImage,yImage,zImage,'CData',img,'FaceColor','texturemap');
end
xlabel('PCA1')
ylabel('PCA2')
zlabel('PCA3')

%% Nodes and Links

[num, ~] = size(image_archive);

for i = 1:num
    w(i,:) = (mink(distance(i,:),11));
end
weight = w(:,2:11); % Find 10 smallest distance differences from PCs (higher corralation between 2 nodes)

for i = 1:num
    for j = 1:10
        finder(i,j) = find(weight(i,j) == distance(i,:)); % Match node number with distance measures
    end
end

v = [1:num];
u = repelem(v,10);

linkdesc1 = [u];
linkdesc2 = reshape(finder(:,:,1)',1,[]);
linkdesc3 = reshape(weight(:,:,1)',1,[]); % Organize data for node and edge arrays

Nodes = sortcombine(:,1); %Output for network software
Edges = [linkdesc1;linkdesc2;linkdesc3]; %Output for network software
