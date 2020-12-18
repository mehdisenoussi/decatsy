# script to compute and plot ERPs of ISI1

import numpy as np
from scipy import signal as sig
from scipy import stats
import mne
from mne.time_frequency import tfr_morlet

def plot_shadederr(subp, curve_val, error_val, color = 'blue', x = None, xlim = None, ylim = None, label = None, linestyle = '-', alpha = 1, linewidth = 1):
	subp.plot(x, curve_val, color = color, label = label, alpha = alpha, linestyle = linestyle, linewidth = linewidth)
	if np.any(error_val):
		subp.fill_between(x, curve_val + error_val, curve_val - error_val, color = color, alpha = .2)
	pl.grid(); pl.ylim(ylim); pl.xlim(xlim)
	if label != None: pl.legend()


obs_all = np.array([	   1,	  3,     4,     5,     6,     8,     9,		10,    11,    12,    13,    14, 	15,		16,		17, 	19])
obs_group_all = np.array([ 4,     1,     3,     4,     2,     3,     1,	 	 2,     2,     1,     3,	 4, 	 4, 	 1, 	 2, 	 3])
sesstype_all = np.array([['SBA', 'FBA', 'SBA', 'SBA', 'FBA', 'SBA', 'FBA',	'FBA', 'FBA', 'FBA', 'SBA', 'SBA',  'SBA', 	'FBA', 	'FBA',  'SBA'],
						[ 'FBA', 'SBA', 'FBA', 'FBA', 'SBA', 'FBA', 'SBA',	'SBA', 'SBA', 'SBA', 'FBA', 'FBA',  'FBA', 	'SBA', 	'SBA',  'FBA']])
n_obs = len(obs_all)

base_path = '/Volumes/mehdimac/lpp/decatsy/decatsy/decatsy_data/'

# get obs 1 sess 1 data to have some info on timing, n electrodes, etc.
epochs = mne.read_epochs(base_path\
	+ 'subj1/eeg_files/subj1_sess1_no_polyfit_allclean_-.6_3.1s_baseline_-.2_-.01s_data_noNotch_filt-None-NoneHz_epo.fif.gz',
	preload = False)


# keep only precue presentation and ISI1
start_t = -.2; end_t = 2.120
n_timep = 465
timeps = np.linspace(start_t, end_t, n_timep)

n_elec = len(epochs.ch_names)

srate = epochs.info['sfreq']

which_mask = 'all'
which_contrast = 'precue'

# FILTERING?
high_pass = None
low_pass = 30

erp_all = np.zeros(shape = [len(obs_all), 2, 2, n_elec, n_timep], dtype=np.float32)

# load EEG data
for sesstype_ind, sess_type in enumerate(['SBA', 'FBA']):
	for obs_ind, obs_i in enumerate(obs_all):
		# determine session number based on the session type (SBA or FBA) and sesstype_all array
		sess_i = np.int(np.argwhere(sesstype_all[:, obs_ind] == sess_type)[0]) + 1

		obs_path = base_path + 'subj%i/' % obs_i
		obs_eegpath = obs_path + 'eeg_files/'

		# get EEG data
		ep_orig = mne.read_epochs(obs_path\
			+ 'eeg_files/subj%i_sess%i_no_polyfit_allclean_-.6_3.1s_baseline_-.2_-.01s_data_Notch_filt-None-NoneHz_epo.fif.gz'\
			% (obs_i, sess_i), preload=True, verbose=False)
		# get log data
		log_data = ep_orig.metadata.copy()

		################################################################################
		# 								ERP 										   #
		################################################################################
		ep_erp = ep_orig.copy().crop(tmin = start_t, tmax = end_t)

		if (low_pass != None) | (high_pass != None):
			ep_erp = ep_erp.filter(high_pass, low_pass, n_jobs = -1, fir_design = 'firwin', verbose=50)

		# select data (e.g. only correct or only valid trials)
		if which_mask == 'correct':
			mask_trial = log_data['correctResp'].values.astype(np.bool)
		elif which_mask == 'valid':
			mask_trial = log_data['validity'].values.astype(np.bool)
		elif which_mask == 'valid_correct':
			mask_trial = log_data['correctResp'].values.astype(np.bool) & log_data['validity'].values.astype(np.bool)
		elif which_mask == 'all':
			mask_trial = np.ones(len(log_data['correctResp']), dtype = np.bool)

		# get the labels of interest for our contrast (e.g. in SBA "left attention" versus "right attention")
		# find out which precue instructs "right" in SBA and "horizontal" in FBA
		obs_group = obs_group_all[obs_ind]
		if obs_group in [1, 3]: cues = [45, 0]
		else: cues = [0, 45]

		if which_contrast == 'precue':
			labels = (log_data['precue'].values == cues[1]).astype(np.int)[mask_trial]
		elif which_contrast == 'correct':
			labels = log_data['correctResp'].values[mask_trial]
		data_erp = ep_erp.get_data()[mask_trial, :, :]
		erp_all[obs_ind, sesstype_ind, :, :, :] = np.array([data_erp[labels==lab_i, :, :].mean(axis=0) for lab_i in np.unique(labels)])
 
		del ep_orig, ep_erp

# get the channel names and make it into a numpy array to be able to look up channel index
ch_names = np.array(epochs.ch_names)
# which channel do we want to plot?
elec_name = 'POz'
# find the channel index
elec_ind = int(np.argwhere(ch_names==elec_name).squeeze())

fig, axs = pl.subplots(1, 2)
# SA and FBA
for cond_ind in np.arange(2):
	ax = axs[cond_ind]
	# each precue (e.g. left or right for SA, hori or vert for FBA)
	for i in np.arange(2):
		# plot the curve with shaded area representing SEM
		plot_shadederr(subp=ax, curve_val=erp_all[:, cond_ind, i, elec_ind, :].mean(axis=0),
			error_val=erp_all[:, cond_ind, i, elec_ind, :].std(axis=0)/(n_obs**.5), color=['b', 'r'][i],
			x=timeps, label=[['left', 'right'],['horizontal', 'vertical']][cond_ind][i])
		# put a label on the X-axis
		ax.set_xlabel('Time from precue onset (s)')
		# put a label on the Y-axis
		ax.set_ylabel('Potential (uV)')
	ax.set_title(['SA', 'FBA'][cond_ind])
	# display legend for each curve
	ax.legend()
	# set the X-axis and Y-axis limits
	ax.set_xlim([start_t, end_t])
	ax.set_ylim([-2.5e-6, 2.5e-6])
	# put a grid on the plot
	ax.grid()
# put a title at the top of the entire figure
pl.suptitle('Elec: %s - mask: %s trials - contrast: %s' % (elec_name, which_mask, which_contrast))





