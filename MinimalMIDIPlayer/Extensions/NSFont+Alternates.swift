//
//  NSFont+Alternates.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 01.09.18.
//  Copyright © 2018 Peter Wunder. All rights reserved.
//

import Cocoa

extension NSFont {

    private func addAttributes(attributes: [[NSFontDescriptor.FeatureKey: Any]]) -> NSFont? {
        let fontAttributes = self.fontDescriptor.fontAttributes
        var featureSettings = fontAttributes[.featureSettings] as? [[NSFontDescriptor.FeatureKey: Any]] ?? []

        for attr in attributes {
            featureSettings.append(attr)
        }

        let newFontAttributes: [NSFontDescriptor.AttributeName: Any] = [
            .featureSettings: featureSettings
        ]

        let desc = self.fontDescriptor.addingAttributes(newFontAttributes)
        return NSFont(descriptor: desc, size: self.pointSize)
    }

    private func enableStylisticAlternate(ss: Int) -> NSFont? {
        let alternates = [
            kStylisticAltOneOnSelector, kStylisticAltTwoOnSelector, kStylisticAltThreeOnSelector, kStylisticAltFourOnSelector, kStylisticAltFiveOnSelector,
            kStylisticAltSixOnSelector, kStylisticAltSevenOnSelector, kStylisticAltEightOnSelector, kStylisticAltNineOnSelector, kStylisticAltTenOnSelector,
            kStylisticAltElevenOnSelector, kStylisticAltTwelveOnSelector, kStylisticAltThirteenOnSelector, kStylisticAltFourteenOnSelector, kStylisticAltFifteenOnSelector,
            kStylisticAltSixteenOnSelector, kStylisticAltSeventeenOnSelector, kStylisticAltEighteenOnSelector, kStylisticAltNineteenOnSelector, kStylisticAltTwentyOnSelector
        ]

        guard ss >= 1 && ss <= 20 else {
            return nil
        }

        let featureSettings = [[
            NSFontDescriptor.FeatureKey.typeIdentifier: kStylisticAlternativesType,
            NSFontDescriptor.FeatureKey.selectorIdentifier: alternates[ss-1]
        ]]

        return self.addAttributes(attributes: featureSettings)
    }

    private func disableStylisticAlternate(ss: Int) -> NSFont? {
        let alternates = [
            kStylisticAltOneOffSelector, kStylisticAltTwoOffSelector, kStylisticAltThreeOffSelector, kStylisticAltFourOffSelector, kStylisticAltFiveOffSelector,
            kStylisticAltSixOffSelector, kStylisticAltSevenOffSelector, kStylisticAltEightOffSelector, kStylisticAltNineOffSelector, kStylisticAltTenOffSelector,
            kStylisticAltElevenOffSelector, kStylisticAltTwelveOffSelector, kStylisticAltThirteenOffSelector, kStylisticAltFourteenOffSelector, kStylisticAltFifteenOffSelector,
            kStylisticAltSixteenOffSelector, kStylisticAltSeventeenOffSelector, kStylisticAltEighteenOffSelector, kStylisticAltNineteenOffSelector, kStylisticAltTwentyOffSelector
        ]

        guard ss >= 1 && ss <= 20 else {
            return nil
        }

        let featureSettings = [[
            NSFontDescriptor.FeatureKey.typeIdentifier: kStylisticAlternativesType,
            NSFontDescriptor.FeatureKey.selectorIdentifier: alternates[ss-1]
        ]]

        return self.addAttributes(attributes: featureSettings)
    }

	var traditionalNumbers: NSFont? {
		let featureSettings = [[
			NSFontDescriptor.FeatureKey.typeIdentifier: kNumberCaseType,
			NSFontDescriptor.FeatureKey.selectorIdentifier: kLowerCaseNumbersSelector
			]]

		return self.addAttributes(attributes: featureSettings)
	}

    var monospacedNumbers: NSFont? {
        let featureSettings = [[
            NSFontDescriptor.FeatureKey.typeIdentifier: kNumberSpacingType,
            NSFontDescriptor.FeatureKey.selectorIdentifier: kMonospacedNumbersSelector
        ]]

        return self.addAttributes(attributes: featureSettings)
    }

    var smallCapsUpper: NSFont? {
        let featureSettings = [[
            NSFontDescriptor.FeatureKey.typeIdentifier: kUpperCaseType,
            NSFontDescriptor.FeatureKey.selectorIdentifier: kUpperCaseSmallCapsSelector
        ]]

        return self.addAttributes(attributes: featureSettings)
    }

    var smallCapsLower: NSFont? {
        let featureSettings = [[
            NSFontDescriptor.FeatureKey.typeIdentifier: kLowerCaseType,
            NSFontDescriptor.FeatureKey.selectorIdentifier: kLowerCaseSmallCapsSelector
        ]]

        return self.addAttributes(attributes: featureSettings)
    }

    var openSixAndNine: NSFont? {
        return self.enableStylisticAlternate(ss: 1)
    }

    var openFour: NSFont? {
        return self.enableStylisticAlternate(ss: 2)
    }

	var verticallyCenteredColon: NSFont? {
		return self.enableStylisticAlternate(ss: 3)
	}

    var highLegibility: NSFont? {
        return self.enableStylisticAlternate(ss: 6)
    }

    var openNumbers: NSFont? {
        return self.openSixAndNine?.openFour
    }

    var fractions: NSFont? {
        let featureSettings = [[
            NSFontDescriptor.FeatureKey.typeIdentifier: kFractionsType,
            NSFontDescriptor.FeatureKey.selectorIdentifier: kDiagonalFractionsSelector
        ]]

        return self.addAttributes(attributes: featureSettings)
    }

	var superscript: NSFont? {
		let featureSettings = [[
			NSFontDescriptor.FeatureKey.typeIdentifier: kVerticalPositionType,
			NSFontDescriptor.FeatureKey.selectorIdentifier: kSuperiorsSelector
		]]

		return self.addAttributes(attributes: featureSettings)
	}

}
