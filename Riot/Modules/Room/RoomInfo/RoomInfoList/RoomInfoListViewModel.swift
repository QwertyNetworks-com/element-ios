// File created from ScreenTemplate
// $ createScreen.sh Room2/RoomInfo RoomInfoList
/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

final class RoomInfoListViewModel: NSObject, RoomInfoListViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let room: MXRoom
    
    // MARK: Public

    weak var viewDelegate: RoomInfoListViewModelViewDelegate?
    weak var coordinatorDelegate: RoomInfoListViewModelCoordinatorDelegate?
    
    var numberOfMembers: Int {
        return Int(room.summary.membersCount.joined)
    }
    var isEncrypted: Bool {
        return room.summary.isEncrypted
    }
    var basicInfoViewModel: RoomInfoBasicTableViewCellVM {
        return self
    }
    var roomTopic: String? {
        return room.summary.topic
    }
    
    // MARK: - Setup
    
    init(session: MXSession, room: MXRoom) {
        self.session = session
        self.room = room
        super.init()
        startObservingSummaryChanges()
    }
    
    deinit {
        stopObservingSummaryChanges()
    }
    
    // MARK: - Public
    
    func process(viewAction: RoomInfoListViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .navigate(let target):
            self.navigate(to: target)
        case .leave:
            self.leave()
        case .cancel:
            self.coordinatorDelegate?.roomInfoListViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func startObservingSummaryChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(roomSummaryUpdated(_:)), name: .mxRoomSummaryDidChange, object: room.summary)
    }
    
    private func stopObservingSummaryChanges() {
        NotificationCenter.default.removeObserver(self, name: .mxRoomSummaryDidChange, object: nil)
    }
    
    @objc private func roomSummaryUpdated(_ notification: Notification) {
        //  force update view
        self.update(viewState: .loaded)
    }
    
    private func loadData() {
        self.update(viewState: .loaded)
    }
    
    private func navigate(to target: RoomInfoListTarget) {
        self.coordinatorDelegate?.roomInfoListViewModel(self, wantsToNavigateTo: target)
    }
    
    private func leave() {
        self.stopObservingSummaryChanges()
        self.update(viewState: .loading)
        self.room.leave { (response) in
            switch response {
            case .success:
                self.coordinatorDelegate?.roomInfoListViewModelDidCancel(self)
            case .failure(let error):
                self.startObservingSummaryChanges()
                self.update(viewState: .error(error))
            }
        }
    }
    
    private func update(viewState: RoomInfoListViewState) {
        self.viewDelegate?.roomInfoListViewModel(self, didUpdateViewState: viewState)
    }
}

extension RoomInfoListViewModel: RoomInfoBasicTableViewCellVM {
    
    func setAvatar(in avatarImageView: MXKImageView) {
        let avatarImage = AvatarGenerator.generateAvatar(forMatrixItem: room.roomId, withDisplayName: room.summary.displayname)
        
        if let avatarUrl = room.summary.avatar ?? session.roomSummary(withRoomId: room.roomId)?.avatar {
            avatarImageView.enableInMemoryCache = true

            avatarImageView.setImageURI(avatarUrl,
                                        withType: nil,
                                        andImageOrientation: .up,
                                        toFitViewSize: avatarImageView.frame.size,
                                        with: MXThumbnailingMethodCrop,
                                        previewImage: avatarImage,
                                        mediaManager: session.mediaManager)
        } else {
            avatarImageView.image = avatarImage
        }
    }
    func setEncryptionIcon(in imageView: UIImageView) {
        guard let summary = room.summary else {
            imageView.image = nil
            imageView.isHidden = true
            return
        }
        
        if summary.isEncrypted {
            imageView.isHidden = false
            imageView.image = EncryptionTrustLevelBadgeImageHelper.roomBadgeImage(for: summary.roomEncryptionTrustLevel())
        } else {
            imageView.isHidden = true
        }
    }
    
    var roomName: String? {
        return room.summary.displayname
    }
    
    var roomAddress: String? {
        return room.summary.aliases?.first
    }
    
}
