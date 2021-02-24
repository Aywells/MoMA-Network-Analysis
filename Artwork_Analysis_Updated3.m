%%Program to read-resize-organize color images called from URL's and run
%%PCA for euclidian distance measures (similarity links) for artwork to
%%artwork network

% As of 11/5/2019: This program is built to analize artwork-artwork
% interactions with euclidian distance similarity links; Raw data is prone
% to error and needs to be checked; will make further sophistication to the
% network ability, linkage importance proof and dynamic interactions.

%Read table and call urls for images -> RBG matrices

full_table = readtable('museum_modern_art_parsed.csv'); % *(NEED TO RECHECK RAW DATA AND CORRECT ERRORS)*
[num,~] = size(full_table);
image_archive = cell(1,num); % Cell holder for all images
NodeNo =  full_table(:,1);
ArtistNo = full_table(:,3);
ArtistNames =  full_table(:,5);
Nationality =  table2array(full_table(:,7));
%1,29,27,11,42 = most common nationalities
% Date =  table2array(full_table(:,10));
nat_grps = findgroups(Nationality);
%idx1 = find(nat_grps == 1);
idx29 = find(nat_grps == 29);
idx27 = find(nat_grps == 27);
%idx11 = find(nat_grps == 11);
%idx42 = find(nat_grps == 42);
idx = [idx27;idx29];
num = length(idx);
% mostcommon = mode(nat_grps);
% tmp = find(nat_grps == 1);
% nat_grps(tmp,:)="";
% tmp = find(nat_grps == 29);
% nat_grps(tmp,:)="";
% tmp = find(nat_grps == 27);
% nat_grps(tmp,:)="";
% tmp = find(nat_grps == 11);
% nat_grps(tmp,:)="";

URLlist = string(table2array(full_table(idx,19))); % URLs for all images

for i = 1:num % If error, "Cannot read URL," run loop at error image count and continue
    %url_img = imread(URLlist(i));
    options = weboptions('Timeout', 30);
    url_img = webread(URLlist(i), options);
    resized_img = imresize(url_img, [300 300]); % Make images same size for PCA
    if sum(size(resized_img)) == 603
        image_archive{i,1} = resized_img; % save uint8 mtx times 3 (RBG) into cell
        nationality_archive{i,1} = Nationality{i};
%         date_archive{i,1} = Date{i};
    end
    if mod(i,50) == 0
        fprintf('Loading Image Number: %d\n', i);
    end
end

image_archive = image_archive(~cellfun('isempty',image_archive));

load chirp.mat;
sound(y);

%for i = 1:num % Remove any B&W images based on uint8 size
%    if sum(size(image_archive{i})) < 603
%        image_archive(i) = [];
%    end
%end

[num, ~] = size(image_archive);

%% Organize RNG mtx's for PCA (every rand ~2000), run PCA and save PCs

tPCAscore = [];
components = 50; % PCA components to use for downstream analysis
artist = [];

universalcountindex = 0;
universalcount = 1;

full_table = full_table(idx,:);

for groupno = 1:1 % Seperate total data into 5 parts to do PCA in chuncks (due to computational limitation)
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
            nationalityholder(count,:) = full_table(j,7);
%             tempdate = cell2mat(table2array(full_table(j,10)));
%             if isequal(tempdate, "")
%                 tempbirthdate = cell2mat(table2array(full_table(j,8)));
%                 tempbirthdate = str2num(tempbirthdate(1:4));
%                 dateholder(count,:) = tempbirthdate+30;
%             else
%                 tempdate = str2num(tempdate(1:4));
%                 dateholder(count,:) = tempdate;
%             end

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
    nationalities((universalcountindex(groupno,1)+1):(universalcountindex(groupno+1,1)),:) = table2array(nationalityholder);
    %dates((universalcountindex(groupno,1)+1):(universalcountindex(groupno+1,1)),:) = dateholder;

end

nat_class = findgroups(nationalities);
% %german
% idxInternational = find(nat_class == 11);
% %american
% idxAmerican = find(nat_class == 1);
% %nat_class(idxInternational,:)=2;
% nat_class = [nat_class(idxInternational,:);nat_class(idxAmerican,:)];
% tPCAscore = [tPCAscore(idxInternational,:);tPCAscore(idxAmerican,:)];

% date_class = findgroups(dates);
% idx1 = find(dates<1920);
% idx2 = find(dates>=1920 & dates<=1939);
% idx3 = find(dates>=1940 & dates<=1959);
% idx4 = find(dates>=1960 & dates<=1979);
% idx5 = find(dates>1979);
% date_class(idx1,:) = 1;
% date_class(idx2,:) = 2;
% date_class(idx3,:) = 3;
% date_class(idx4,:) = 4;
% date_class(idx5,:) = 5;

%date_class = [date_class(idx1,:);date_class(idx2,:);date_class(idx3,:);date_class(idx4,:);date_class(idx5,:)];
%tPCAscore = [tPCAscore(idx1,:);tPCAscore(idx2,:);tPCAscore(idx3,:);tPCAscore(idx4,:);tPCAscore(idx5,:)];

[val,~] = size(tPCAscore);

cvp = cvpartition(val,'HoldOut',0.10);
idxTrain = training(cvp);
idxTest = test(cvp);
dataTrain = tPCAscore(idxTrain,:);
dataTest = tPCAscore(idxTest,:);

mdlsvm = fitcecoc(dataTrain(:,1:2), nat_class(idxTrain));
mdltree = fitctree(dataTrain(:,1:2), nat_class(idxTrain));
mdlKnn = fitcknn(dataTrain(:,1:2), nat_class(idxTrain));
mdlDA = fitcdiscr(dataTrain(:,1:2),nat_class(idxTrain)); 
mdlEn = fitensemble(dataTrain(:,1:2),nat_class(idxTrain),'LogitBoost',100,'Tree');
mdlEn2 = fitensemble(dataTrain(:,1:2),nat_class(idxTrain),'AdaBoostM1',100,'Tree'); 
mdlEn3 = fitensemble(dataTrain(:,1:2),nat_class(idxTrain),'Bag',100,'Tree','Type','classification'); 

predictedLabels_svm = predict(mdlsvm, dataTest(:,1:2));
confMat = confusionmat(nat_class(idxTest), predictedLabels_svm)
predictedLabels_tree = predict(mdltree, dataTest(:,1:2));
confMat = confusionmat(nat_class(idxTest), predictedLabels_tree)
predictedLabels_knn = predict(mdlKnn, dataTest(:,1:2));
confMat = confusionmat(nat_class(idxTest), predictedLabels_knn)
predictedLabels_lda = predict(mdlDA, dataTest(:,1:2));
confMat = confusionmat(nat_class(idxTest), predictedLabels_lda)
predictedLabels_en = predict(mdlEn, dataTest(:,1:2));
confMat = confusionmat(nat_class(idxTest), predictedLabels_en)
predictedLabels_en2 = predict(mdlEn2, dataTest(:,1:2));
confMat = confusionmat(nat_class(idxTest), predictedLabels_en2)
predictedLabels_en3 = predict(mdlEn3, dataTest(:,1:2));
confMat = confusionmat(nat_class(idxTest), predictedLabels_en3)
%% PC distributions and comparisons for artists/artworks

% combine = [artist,tPCAscore];
% sortcombine = sortrows(combine);
% 
% distance = [];
% for m = 1:num
%     for n = 1:num
%     
%         distance(n,m) = sum(abs(tPCAscore(m,:)-tPCAscore(n,:))); % Euclidian distance measures from PCs
%         
%     end
% end
% 
% %% Nodes and Links
% 
% for i = 1:num
%     w(i,:) = (mink(distance(i,:),11));
% end
% weight = w(:,2:11); % Find 10 smallest distance differences from PCs (higher corralation between 2 nodes)
% 
% for i = 1:num
%     for j = 1:10
%         finder(i,j) = find(weight(i,j) == distance(i,:)); % Match node number with distance measures
%     end
% end
% 
% v = [1:num];
% u = repelem(v,10);
% 
% linkdesc1 = [u];
% linkdesc2 = reshape(finder(:,:,1)',1,[]);
% linkdesc3 = reshape(weight(:,:,1)',1,[]); % Organize data for node and edge arrays
% 
% Nodes = sortcombine(:,1); %Output for network software
% Edges = [linkdesc1;linkdesc2;linkdesc3]; %Output for network software
% 
% scatter3(tPCAscore(:,1),tPCAscore(:,2),tPCAscore(:,3),'x')
% axis equal
% xlabel('1st Principal Component')
% ylabel('2nd Principal Component')
% zlabel('3rd Principal Component')
% % 
% X = tPCAscore(:,1:3);
% idx = kmeans(X,7,'Replicates',50);
% figure(1);
% scatter3(X(idx==1,1),X(idx==1,2),X(idx==1,3),'r')
% hold on
% scatter3(X(idx==2,1),X(idx==2,2),X(idx==2,3),'b')
% hold on
% scatter3(X(idx==3,1),X(idx==3,2),X(idx==3,3),'k')
% hold on
% scatter3(X(idx==4,1),X(idx==4,2),X(idx==4,3),'g')
% hold on
% scatter3(X(idx==5,1),X(idx==5,2),X(idx==5,3),'y')
% hold on
% scatter3(X(idx==6,1),X(idx==6,2),X(idx==6,3),'o')
% hold on
% scatter3(X(idx==7,1),X(idx==7,2),X(idx==7,3),'m')
% title 'Cluster Assignments'
% hold off
% 
% figure(2)
% Z = linkage(X,'average');
% Y = pdist(X);
% dendrogram(Z)
% c = cophenet(Z,Y)
% grp = cluster(Z,'maxclust',7);
% figure(3)
% silhouette(X,grp)
% figure(4)
% silhouette(X,idx)
% metric = {'CalinskiHarabasz','DaviesBouldin','gap','silhouette'};
% for i = 1:length(metric)
%     eva_kmeans{i} = evalclusters(X,'kmeans',metric{i},'KList',[1:10])
%       eva_linkage{i} = evalclusters(X,'linkage',metric{i},'KList',[1:10])
%     eva_gm{i} = evalclusters(X,'gmdistribution',metric{i},'KList',[1:10])
% end


