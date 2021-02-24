%%Program to read-resize-organize color images called from URL's and run
%%PCA for euclidian distance measures (similarity links) for artwork to
%%artwork network

%Read table and call urls for images -> RBG matrices

full_table = readtable('museum_modern_art_parsed.csv'); % *(NEED TO RECHECK RAW DATA AND CORRECT ERRORS)*
[num,~] = size(full_table);
num = 600;
image_archive = cell(1,num); % Cell holder for all images
NodeNo =  full_table(:,1);
ArtistNo = full_table(:,3);
ArtistNames =  full_table(:,5);
URLlist = string(table2array(full_table(:,19))); % URLs for all images
for i = 1:num % If error, "Cannot read URL," run loop at error image count and continue
    %url_img = imread(URLlist(i));
    options = weboptions('Timeout', 30);
    url_img = webread(URLlist(i), options);
    resized_img = imresize(url_img, [300 300]); % Make images same size for PCA
    if sum(size(resized_img)) == 603
        image_archive{1,i} = edge(rgb2gray(resized_img),'canny');%resized_img; % save uint8 mtx times 3 (RBG) into cell
    end
    if mod(i,50) == 0
        fprintf('Loading Image Number: %d\n', i);
    end
end

load chirp.mat;
sound(y);

image_archive = image_archive(~cellfun('isempty', image_archive));
num = size(image_archive,2);

%% Organize RNG mtx's for PCA (every rand ~2000), run PCA and save PCs

tPCAscore = [];
components = 50; % PCA components to use for downstream analysis
artist = [];

universalcountindex = 0;
universalcount = 1;

for groupno = 1:5 % Seperate total data into 5 parts to do PCA in chuncks (due to computational limitation)
    count = 1;
    clear group; clear randartist; clear holder;
    for j = 1:num % Edit ending range from new image_archive size
       
        if table2array(full_table(j,2)) == groupno % Call random generated groups (1-5) for batch PCA computing
            holder = image_archive{j};
            %holderR = reshape(holder(:,:,1)',[],1);
            %holderB = reshape(holder(:,:,2)',[],1);
            %holderG = reshape(holder(:,:,3)',[],1);
            holderRBG = reshape(holder(:,:)',[],1);
            %holderRBG = vertcat(vertcat(holderR,holderB),holderG); % 1 long pixal vector for each image
            %group(:,count) = double(holderRBG./255.0);
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
    tPCAscore((universalcountindex(groupno,1)+1):(universalcountindex(groupno+1,1)),:) = score(:,1:components); % Organize PCA data with correct artiwork number
    artist((universalcountindex(groupno,1)+1):(universalcountindex(groupno+1,1)),:) = table2array(randartist);
    
    figure;
    %plot(score(:,1),score(:,2),'+');
    plot3(score(:,1),score(:,2),score(:,3),'+');
    
end

%% PC distributions and comparisons for artists/artworks

combine = [artist,tPCAscore];
sortcombine = sortrows(combine);

distance = [];
for m = 1:num
    for n = 1:num
    
    distance(n,m) = sum(abs(tPCAscore(m,:)-tPCAscore(n,:))); % Euclidian distance measures from PCs
        
    end
end

%% Nodes and Links

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
