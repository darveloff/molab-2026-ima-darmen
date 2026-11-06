/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SwiftUI

struct CardListView: View {
  @ObservedObject var cardListViewModel = CardListViewModel()
  @State var showForm = false
  @State var searchText = ""

  var allCards: [CardViewModel] {
    cardListViewModel.cardViewModels
  }

  var learnedCount: Int {
    allCards.filter { $0.card.learned == true }.count
  }

  var visibleCards: [CardViewModel] {
    if searchText.isEmpty {
      return allCards
    }
    return allCards.filter { $0.card.question.localizedCaseInsensitiveContains(searchText) }
  }

  var body: some View {
    NavigationView {
      VStack {
        Text("\(allCards.count) cards, \(learnedCount) learned")
          .foregroundColor(.gray)
        Spacer()
        VStack {
          GeometryReader { geometry in
            ScrollView(.horizontal) {
              HStack(spacing: 10) {
                ForEach(visibleCards) { cardViewModel in
                  CardView(cardViewModel: cardViewModel)
                    .padding([.leading, .trailing])
                }
              }.frame(height: geometry.size.height)
            }
          }
        }
        Spacer()
      }
      .sheet(isPresented: $showForm) {
        NewCardForm(cardListViewModel: cardListViewModel)
      }
      .navigationBarTitle("🔥 Fire Cards")
        // swiftlint:disable multiple_closures_with_trailing_closure
        .navigationBarItems(
          leading: Button(action: { cardListViewModel.shuffle() }) {
            Image(systemName: "shuffle")
              .font(.title2)
          },
          trailing: Button(action: { showForm.toggle() }) {
            Image(systemName: "plus")
              .font(.title)
          })
        .searchable(text: $searchText, prompt: "Search questions")
    }
    .navigationViewStyle(StackNavigationViewStyle())
  }
}

struct CardListView_Previews: PreviewProvider {
  static var previews: some View {
    CardListView(cardListViewModel: CardListViewModel())
  }
}
